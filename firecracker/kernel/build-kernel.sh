#!/bin/bash

set -xe

git clone --branch v6.7 --depth 1 https://github.com/torvalds/linux.git linux
cd linux
# git checkout v4.20
# git checkout v6.7
# wget https://raw.githubusercontent.com/firecracker-microvm/firecracker/main/resources/microvm-kernel-x86_64.config -O .config
wget https://raw.githubusercontent.com/firecracker-microvm/firecracker/main/resources/guest_configs/microvm-kernel-ci-x86_64-6.1.config -O .config
# yes "" | make oldconfig
make olddefconfig
# make silentoldconfig
make -j32 vmlinux

# uncompressed kernel image available under ./vmlinux
