#!/usr/bin/bash
KERNEL_VERSION="$1"
KERNEL_IMAGE="$2"

/dev/nvme0n1p1

sudo efibootmgr --verbose --create --disk /dev/nvme0n1 --part 1 --loader "\EFI\fedora\fedora.efi" --label "Fedora-EFI"

UUID_EFI_PARTITION="$(findmnt -kno UUID /boot/efi)"
ROOT_UUID="$(findmnt -kno UUID /)"
ROOTFSTYPE=$(findmnt -kno FSTYPE /)

DISTRO="fedora"
dracut --verbose --force --uefi --kver "${KERNEL_IMAGE}" "/boot/efi/EFI/fedora/fedora.efi" --force-drivers "nvidia nvidia_modeset nvidia_uvm nvidia_drm"

/etc/kernel/postinst.d/symlink-kernel
arguments:
'6.1.8-200.fc37.x86_64' '/boot/vmlinuz-6.1.8-200.fc37.x86_64' SUCCESS: symlink created /boot/vmlinuz to /boot/vmlinuz-6.1.8-200.fc37.x86_64
SUCCESS: symlink created /boot/initramfs.img to /boot/initramfs-6.1.8-200.fc37.x86_64.img

dracut --verbose --force --uefi --force-drivers " nvidia nvidia_modeset nvidia_uvm nvidia_drm " --kver "6.1.8-200.fc37.x86_64" "/boot/efi/EFI/fedora/fedora.efi"

sudo dracut --force --kver "${kk##*vmlinuz-}" --kernel-cmdline "/@/boot/vmlinuz-$(uname -r) root=UUID=${ROOT_UUID} rootfstype=${ROOTFSTYPE} ro rootflags=subvol=@ add_efi_memmap text verbose" --confdir "/etc/dracut.conf.d" --kernel-image "${kk}" --uefi --verbose

dracut --verbose --force --uefi --kver "6.1.8-200.fc37.x86_64" "/boot/efi/EFI/fedora/fedora.efi"
