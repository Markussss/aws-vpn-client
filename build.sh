#!/bin/bash

if [ ! -f ./openvpn-2.5.8.zip ]; then
  curl -L https://github.com/OpenVPN/openvpn/archive/v2.5.8.zip -o openvpn-2.5.8.zip
fi


cleanup() {
  rm -rf openvpn-2.5.8 && \
  rm openvpn-2.5.8.zip
}
trap cleanup exit

unzip openvpn-2.5.8.zip && \
  cp openvpn-v2.5.8-aws.patch openvpn-2.5.8 && \
  cd openvpn-2.5.8 && \
  patch -p1 < openvpn-v2.5.8-aws.patch && \
  autoreconf -i -v -f && \
  ./configure && \
  make && \
  cd .. && \
  mv openvpn-2.5.8/src/openvpn/openvpn .
