#!/bin/bash

set -e

if [ ! -f ./openvpn ]; then
  ./build.sh
fi

if [ ! -f ./user-and-pass.txt ]; then
  printf "N/A\nACS::35001" > user-and-pass.txt
  chmod 600 user-and-pass.txt
fi

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
  timeout "$wait_seconds"s go run server.go &
  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done
  ((++wait_seconds))
}

while true; do
  cp vpn.{conf,modified.conf}

  sed -i '/^auth-user-pass.*$/d' vpn.modified.conf
  sed -i '/^auth-federate.*$/d' vpn.modified.conf
  sed -i '/^auth-retry interact.*$/d' vpn.modified.conf

  VPN_HOST=$(cat vpn.modified.conf | grep 'remote '| cut -d ' ' -f2)
  PORT=$(cat vpn.modified.conf | grep 'remote '| cut -d ' ' -f3)
  PROTO=$(cat vpn.modified.conf | grep 'proto '| cut -d " " -f2)

  echo "Connecting to $VPN_HOST on port $PORT/$PROTO"

  # create random hostname prefix for the vpn gw
  RAND=$(openssl rand -hex 12)

  # resolv manually hostname to IP, as we have to keep persistent ip address
  SRV=$(dig a +short "${RAND}.${VPN_HOST}"|head -n1)

  # cleanup
  rm -f saml-response.txt saml-user-and-pass.txt

  echo "Getting SAML redirect URL from the AUTH_FAILED response (host: ${SRV}:${PORT})..."

  touch log.txt
  tail -n0 -f log.txt | sed -e '/AUTH_FAILED,CRV1/q' && pkill openvpn &

  ./openvpn --config vpn.modified.conf --verb 3 \
    --proto "$PROTO" --remote "${SRV}" "${PORT}" \
    --auth-user-pass user-and-pass.txt | tee log.txt 2>&1

  OVPN_OUT=$(grep "AUTH_FAILED,CRV1" log.txt)

  rm log.txt

  URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')
  unameOut="$(uname -s)"
  case "${unameOut}" in
      Linux*)     su "$SUDO_USER" -c "xdg-open $URL";;
      Darwin*)    open "$URL";;
      *)          printf "\n\nOpen this URL in your browser: %s" "$URL";;
  esac

  wait_file "saml-response.txt" 120 || {
    echo "SAML Authentication timed out"
    exit 1
  }

  # get SID from the reply
  VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')

  echo "Running OpenVPN."

  SAML=$(cat saml-response.txt)

  printf "%s\n%s\n" "N/A" "CRV1::${VPN_SID}::${SAML}" > saml-user-and-pass.txt

  chmod 600 saml-user-and-pass.txt

  # Finally OpenVPN with a SAML response we got
  # Delete saml-response.txt after connect
  ./openvpn --config vpn.modified.conf \
    --verb 3 --auth-nocache --inactive 3600 \
    --proto "$PROTO" --remote "$SRV" "$PORT" \
    --script-security 2 \
    --auth-user-pass saml-user-and-pass.txt
  #  \
  # --route-up '/bin/rm saml-response.txt && /bin/rm saml-user-and-pass.txt'
done;