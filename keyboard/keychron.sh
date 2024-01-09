#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
set -o xtrace

cat <<EOF | sudo tee -a /etc/udev/rules.d/92-viia.rules
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
EOF

sudo udevadm control --reload
sudo udevadm trigger
