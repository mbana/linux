#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
# set -o xtrace

working_interface_setup()
{
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
}

TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/30"

official_interface_setup()
{

  # Setup network interface
  sudo ip link del "$TAP_DEV" 2> /dev/null || true
  sudo ip tuntap add dev "$TAP_DEV" mode tap
  sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
  sudo ip link set dev "$TAP_DEV" up

  # Enable ip forwarding
  sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

  # Set up microVM internet access
  sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE || true
  sudo iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT \
      || true
  sudo iptables -D FORWARD -i tap0 -o eth0 -j ACCEPT || true
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  sudo iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -I FORWARD 1 -i tap0 -o eth0 -j ACCEPT
}

# working_interface_setup
official_interface_setup

API_SOCKET="/tmp/firecracker.socket"
# Remove API unix socket
sudo rm -f "${API_SOCKET}"

# Create the required named pipe:
METRICS_PIPE="$(pwd)/metrics.fifo"
rm -f "${METRICS_PIPE}"
mkfifo "${METRICS_PIPE}"

firecracker --api-sock "${API_SOCKET}" --boot-timer --config-file config-file-guest-internet.json

ssh -i ./ubuntu-22.04.id_rsa root@172.16.0.2 "
ip addr add 172.16.0.2/24 dev eth0
ip link set eth0 up
ip route add default via 172.16.0.1 dev eth0
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
"

# ssh -i ./ubuntu-22.04.id_rsa root@172.16.0.2
