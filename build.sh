#!/bin/bash

if [ ! -f ./openvpn.zip ]; then
  curl -L https://github.com/OpenVPN/openvpn/archive/v2.4.9.zip -o openvpn.zip
fi

unzip openvpn.zip && \
  cp openvpn-v2.4.9-aws.patch openvpn-2.4.9 && \
  cd openvpn-2.4.9 && \
  patch -p1 < openvpn-v2.4.9-aws.patch && \
  autoreconf -i -v -f && \
  ./configure && \
  make && \
  cd .. && \
  mv openvpn-2.4.9/src/openvpn/openvpn . && \
  rm -rf openvpn-2.4.9
