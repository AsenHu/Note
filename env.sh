#!/usr/bin/env bash
system=debian
name=user
pass=$(echo $RANDOM | md5sum | cut -d " " -f1) 
port=$((RANDOM * 8 % 55535 + 10000))
debian_sources_CN=mirrors.tencent.com
debian_sources_ALL=deb.debian.org
ubuntu_sources_CN=mirrors.tencent.com
ubuntu_sources_ALL=archive.ubuntu.com
debian_secSources_CN=mirrors.tencent.com
debian_secSources_ALL=security.debian.org
CFIP=false
debian_netmode=DHCP
debian_DHCP_IPv4=true
debian_DHCP_IPv6=true
debian_DNS="1.1.1.1 2606:4700::1111"
CN=false
