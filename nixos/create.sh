#!/usr/bin/bash
set -e
set -u
set -f

# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-23.11 -I nixos-config=./configuration.nix
# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-unstable -I nixos-config=./nixpkgs/pkgs/desktops/gnome/default.nix

nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-unstable -I nixos-config=./configuration.nix

env QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -chardev spicevmc,id=ch1,name=vdagent -device virtio-serial-pci -device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0 -machine type=q35,accel=kvm -smp 20 -m 32000
