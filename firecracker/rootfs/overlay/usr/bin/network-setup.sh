#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
set -o xtrace

ip addr add 172.16.0.2/24 dev eth0
ip link set eth0 up
ip route add default via 172.16.0.1 dev eth0

echo 'nameserver 8.8.8.8' | tee -a /etc/resolv.conf
