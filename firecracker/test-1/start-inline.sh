#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
set -o xtrace

sudo ip tuntap del tap0 mode tap || true
sudo ip link del tap0 || true

sudo ip tuntap add tap0 mode tap
sudo ip addr add 172.16.0.1/24 dev tap0
sudo ip link set dev tap0 up

sudo sysctl -w net.ipv4.conf.tap0.proxy_arp=1 > /dev/null
sudo sysctl -w net.ipv6.conf.tap0.disable_ipv6=1 > /dev/null
sudo sysctl -p
sysctl -p

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o eth0 -j ACCEPT

# sudo brctl addif docker0 tap0

# sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# sudo iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# sudo iptables -I FORWARD 1 -i tap0 -o eth0 -j ACCEPT

API_SOCKET="/tmp/firecracker.socket"
# Remove API unix socket
sudo rm -f "${API_SOCKET}"

# Create the required named pipe:
METRICS_PIPE="$(pwd)/metrics.fifo"
rm -f "${METRICS_PIPE}"
mkfifo "${METRICS_PIPE}"

firecracker --api-sock "${API_SOCKET}" --config-file config-file.json
