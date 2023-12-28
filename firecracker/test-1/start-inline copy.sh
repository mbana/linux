#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
set -o xtrace

TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/30"

# Setup network interface
sudo ip link del "$TAP_DEV" 2> /dev/null || true
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
sudo ip link set dev "$TAP_DEV" up

# Enable ip forwarding
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# Set up microVM internet access
sudo iptables -t nat -D POSTROUTING -o wlan0 -j MASQUERADE || true
sudo iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT || true
sudo iptables -D FORWARD -i tap0 -o wlan0 -j ACCEPT || true
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -I FORWARD 1 -i tap0 -o wlan0 -j ACCEPT

sudo iptables -t nat -A POSTROUTING -o tap0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan0 -o tap0 -j ACCEPT

brctl addbr br0
brctl addif br0 tap0


API_SOCKET="/tmp/firecracker.socket"
# Remove API unix socket
sudo rm -f "${API_SOCKET}"

# Create the required named pipe:
METRICS_PIPE="$(pwd)/metrics.fifo"
rm -f "${METRICS_PIPE}"
mkfifo "${METRICS_PIPE}"

firecracker --api-sock "${API_SOCKET}" --config-file config-file.json
