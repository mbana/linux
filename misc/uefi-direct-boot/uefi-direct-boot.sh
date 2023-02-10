#!/usr/bin/bash
set -o errexit  # Used to exit upon error, avoiding cascading errors
set -o pipefail # Unveils hidden failures
set -o nounset  # Exposes unset variable

# KERNEL_VERSION="$1"
# KERNEL_IMAGE="$2"
KERNEL_VERSION="6.1.8-200.fc37.x86_64"
KERNEL_IMAGE="/boot/vmlinuz-6.1.8-200.fc37.x86_64"

# UUID_EFI_PARTITION="$(findmnt -kno UUID /boot/efi)"
# ROOT_UUID="$(findmnt -kno UUID /)"
# ROOTFSTYPE=$(findmnt -kno FSTYPE /)

# # root=UUID=97f80d77-33fe-40c5-88db-3ace7c5f10f4 rootfstype=btrfs rootflags=rw,relatime,seclabel,compress=zstd:1,ssd,space_cache=v2,subvolid=257,subvol=/root00,subvol=root00
# # BOOT_IMAGE=(hd1,gpt2)/vmlinuz-6.1.8-200.fc37.x86_64 root=UUID=97f80d77-33fe-40c5-88db-3ace7c5f10f4 ro rootflags=subvol=root00 sysrq_always_enabled=1 rd.driver.blacklist=nouveau nouveau.modeset=0 nvidia-drm.modeset=1 initcall_blacklist=simpledrm_platform_driver_init rd.plymouth=0 plymouth.enable=0 rd.luks=0 rd.lvm=0 rd.md=0 rd.dm=0 nosplash logo.nologo quiet mitigations=off

# KERNEL_CMDLINE="/@/boot/vmlinuz-$(uname -r) root=UUID=${ROOT_UUID} rootfstype=${ROOTFSTYPE} ro rootflags=subvol=@ add_efi_memmap text verbose"

KERNEL_CMDLINE="BOOT_IMAGE=(hd1,gpt2)/boot/vmlinuz root=UUID=97f80d77-33fe-40c5-88db-3ace7c5f10f4 rootfstype=btrfs rootflags=rw,relatime,seclabel,compress=zstd:1,ssd,space_cache=v2,subvolid=257,subvol=/root00,subvol=root00 sysrq_always_enabled=1 add_efi_memmap rd.driver.blacklist=nouveau nouveau.modeset=0 nvidia-drm.modeset=1 initcall_blacklist=simpledrm_platform_driver_init rd.plymouth=0 plymouth.enable=0 rd.luks=0 rd.lvm=0 rd.md=0 rd.dm=0 nosplash logo.nologo quiet mitigations=off"

# DISTRO="fedora"
# dracut --verbose --force --uefi --kver "${KERNEL_IMAGE}" "/boot/efi/EFI/fedora/fedora.efi" --force-drivers "nvidia nvidia_modeset nvidia_uvm nvidia_drm"

# /etc/kernel/postinst.d/symlink-kernel
# arguments:
# '6.1.8-200.fc37.x86_64' '/boot/vmlinuz-6.1.8-200.fc37.x86_64' SUCCESS: symlink created /boot/vmlinuz to /boot/vmlinuz-6.1.8-200.fc37.x86_64
# SUCCESS: symlink created /boot/initramfs.img to /boot/initramfs-6.1.8-200.fc37.x86_64.img

# dracut --verbose --force --uefi --force-drivers " nvidia nvidia_modeset nvidia_uvm nvidia_drm " --kver "6.1.8-200.fc37.x86_64" "/boot/efi/EFI/fedora/fedora.efi"

# sudo dracut --force --kver "${kk##*vmlinuz-}" --kernel-cmdline "/@/boot/vmlinuz-$(uname -r) root=UUID=${ROOT_UUID} rootfstype=${ROOTFSTYPE} ro rootflags=subvol=@ add_efi_memmap text verbose" --confdir "/etc/dracut.conf.d" --kernel-image "${kk}" --uefi --verbose

dracut \
  --verbose \
  --show-modules \
  --force \
  --uefi \
  --kver "${KERNEL_VERSION}" \
  --kernel-image "${KERNEL_IMAGE}" \
  --kernel-cmdline "${KERNEL_CMDLINE}" \
  "/boot/efi/EFI/fedora/fedora.efi"
