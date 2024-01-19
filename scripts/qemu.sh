#!/bin/bash
# ISO="/home/mbana/Downloads/isos/archlinux-2024.01.01-x86_64.iso"
# ISO=/home/mbana/Downloads/isos/Fedora-Workstation-Live-x86_64-39-1.5.iso

  # -enable-kvm \
  # -machine accel=kvm \
  # -cdrom "${ISO}" \

  # -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd \

  # -monitor stdio \

# cp -v /usr/share/edk2/ovmf/OVMF_CODE.fd .
# cp -v /usr/share/edk2/ovmf/OVMF_VARS.fd .
#   -drive if=pflash,format=raw,unit=0,file=./OVMF_CODE.fd,readonly=on \
#   -drive if=pflash,format=raw,unit=1,file=./OVMF_VARS.fd

qemu-system-x86_64 \
  -enable-kvm -machine type=pc-q35-8.2,accel=kvm -device intel-iommu \
  -boot menu=on \
  -smp 20 -m 8192M \
  -net nic -net user \
  -drive file=/dev/nvme0n1,if=virtio,format=raw \
  -cpu host \
  -serial stdio \
  -vga virtio \
  -bios /usr/share/edk2/ovmf/OVMF_CODE.fd