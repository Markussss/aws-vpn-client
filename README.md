# OpenVPN AWS VPN Linux Client

This is an implementation of the [original](https://github.com/samm-git/aws-vpn-client) AWS VPN client PoC with OpenVPN using SAML authentication, based on the docker setup from [rdvencioneck/aws-vpn-client-docker](https://github.com/rdvencioneck/aws-vpn-client-docker). The goal is to have an easy to consume Linux client, and I just didn't find the docker setup to be so easy after all.

See [the original blog post](https://smallhacks.wordpress.com/2020/07/08/aws-client-vpn-internals/) for the implementation details.

## Content of the repository

- [openvpn-v2.5.8-aws.patch](openvpn-v2.5.8-aws.patch) - patch required to build
  AWS compatible OpenVPN v2.5.8, based on the
  [AWS source code](https://amazon-source-code-downloads.s3.amazonaws.com/aws/clientvpn/wpf-v1.2.0/openvpn-2.4.5-aws-1.tar.gz), adjusted for OpenVPN 2.5.8
- (Outdated, but still usable) [openvpn-v2.4.9-aws.patch](openvpn-v2.4.9-aws.patch) - patch required to build
  AWS compatible OpenVPN v2.4.9, based on the
  [AWS source code](https://amazon-source-code-downloads.s3.amazonaws.com/aws/clientvpn/wpf-v1.2.0/openvpn-2.4.5-aws-1.tar.gz) (thanks to @heprotecbuthealsoattac for the link).
- [server.go](server.go) - Go server to listen on http://127.0.0.1:35001 and save
  SAML Post data to the file.
- [build.sh](build.sh) - builds the patched OpenVPN client
- [connect.sh](connect.sh) - connects to the VPN

## How to use

1. Rename your VPN config file to `vpn.conf`
2. Build patched openvpn version by running `./build.sh`
3. Run `sudo ./connect.sh` to connect to the AWS Client VPN

This will attempt to connect as long as the connection fails. For some reason, OpenVPN might fail to establish a connection. This has been mentioned, for example in [threads on serverfault.com](https://serverfault.com/questions/1024546/aws-client-vpn-sso-saml-linux-client). I've experienced that running openvpn as root (with `sudo` greatly reduces the amount of tries it takes to establish a connection).

## Install dependencies

I have installed and built this project by in clean docker images of the following distros, while noting which packages are required for building the patched openvpn client.

### Ubuntu:

```bash
apt install git curl unzip patch gcc automake libtool libssl-dev net-tools liblzo2-dev libpam-dev cmake openssl golang-bin
```

### Fedora

```bash
dnf install git curl unzip patch gcc automake libtool openssl-devel net-tools lzo-devel pam-devel cmake openssl golang-bin
```

### OpenSuse

```bash
zypper install git curl unzip patch gcc automake libtool openssl-devel net-tools-deprecated lzo-devel pam-devel cmake openssl go-doc
```

### Arch

```bash
pacman -S git curl unzip patch gcc automake autoconf libtool openssl net-tools lzo pam make golang-bin
```
