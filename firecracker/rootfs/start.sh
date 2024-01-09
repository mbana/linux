#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
set -o xtrace

sudo /sbin/iptables-save iptables.rules.old

# cat <<EOF > /etc/sysctl.d/99-net.conf
# net.ipv6.conf.default.disable_ipv6=1
# net.ipv6.conf.all.disable_ipv6=1
# net.ipv4.ip_forward=1
# net.ipv6.conf.lo.disable_ipv6 = 1
# net.ipv6.conf.eth0.disable_ipv6=1
# EOF

sudo ip tuntap add tap0 mode tap

sudo ip addr add 172.16.0.1/24 dev tap0
sudo ip link set tap0 up
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o eth0 -j ACCEPT

curl --unix-socket /tmp/firecracker.socket -i \
  -X PUT 'http://localhost/network-interfaces/eth0' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "iface_id": "eth0",
      "guest_mac": "AA:FC:00:00:00:01",
      "host_dev_name": "tap0"
    }'

sudo ip link del tap0

if [[ -f iptables.rules.old ]]; then
    sudo iptables-restore < iptables.rules.old
fi

sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward" # usually the default
