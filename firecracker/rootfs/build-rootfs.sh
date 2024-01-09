#!/usr/bin/bash
set -e
set -u
set -f
set -o pipefail
# set -x
set -o xtrace

# ssh-keygen -t rsa -b 4096 -C "root (firecracker)" -f ./id_rsa -P ""

dd if=/dev/zero of=rootfs.ext4 bs=1M count=5000
mkfs.ext4 rootfs.ext4
mkdir -pv /tmp/rootfs
mount -v rootfs.ext4 /tmp/rootfs

debootstrap jammy /tmp/rootfs

# Set a hostname.
echo "firecracker" > /tmp/rootfs/etc/hostname

# Copy ssh key

# deb http://archive.ubuntu.com/ubuntu    jammy           main

cat <<EOF | tee -a /tmp/rootfs/etc/apt/sources.list
deb http://de.archive.ubuntu.com/ubuntu jammy           main restricted universe
deb http://de.archive.ubuntu.com/ubuntu jammy-security  main restricted universe
deb http://de.archive.ubuntu.com/ubuntu jammy-updates   main restricted universe
EOF

echo "firecracker" > /tmp/rootfs/etc/hostname

arch-chroot /tmp/rootfs /bin/bash <<"EOF"
export DEBIAN_FRONTEND=noninteractive

apt update -y
apt install -y udev systemd-sysv openssh-server iproute2 curl socat python3-minimal iperf3 iputils-ping fio kmod tmux hwloc-nox vim-tiny trace-cmd linuxptp msr-tools cpuid vim tmux screen ethtool gawk git gnupg htop man wget busybox iperf sudo

# # Set the root password to root when logging in through the VM's ttyS0 console
# RUN echo "root:root" | chpasswd

passwd -d root

# yes | unminimize
EOF

umount -v /tmp/rootfs
