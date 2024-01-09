mount --bind /dev /rootfs/dev
mount --bind /dev/pts /rootfs/dev/pts
mount --bind /proc /rootfs/proc
mount --bind /sys /rootfs/sys
mount --bind /var /rootfs/var
mount --bind /tmp /rootfs/tmp
chroot /rootfs /bin/bash
