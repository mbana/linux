#!/usr/bin/env bash
set -e
set -u
set -f
set -o pipefail
# set -x
# set -o xtrace

sudo ip link add name br0 type bridge || true
sudo ip link set br0 up || true
ip link show || true
sudo ip link set eth0 master br0 || true

# Create the required named pipe:
rm "$(pwd)/metrics.fifo"
mkfifo "$(pwd)/metrics.fifo"
# The Metrics system also works with usual files:
touch "$(pwd)/metrics.file"

print_metrics()
{
  while true; do
    if read line < "$(pwd)/metrics.fifo"; then
      echo "${line}"
    fi
  done
}

API_SOCKET="/tmp/firecracker.socket"
# Remove API unix socket
sudo rm -f "${API_SOCKET}"

firecracker \
  --api-sock "${API_SOCKET}" \
  --config-file config-file-bridge-to-vm.json
