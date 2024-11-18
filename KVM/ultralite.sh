#!/bin/bash

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

dir_to_uuid() {
    local dir dev
    dir=$1
    dev=$(df --output=source "$dir" | tail -1)  # Get the device name of the filesystem containing the directory
    blkid -s UUID -o value "$dev"  # Get the UUID of the device
}

rm -rvf /x /archlinux-x86_64.iso
curl -o /archlinux-x86_64.iso "https://iso.meson.cc/ultralite/latest/archlinux-x86_64.iso"

mkdir -p /x
mount -o loop /archlinux-x86_64.iso /x

uuid=$(dir_to_uuid /)

mv /boot/grub/grub.cfg /boot/grub/grub.cfg.bak
{
    cat << EOF
search --no-floppy --set=root --fs-uuid $uuid
loopback loop /archlinux-x86_64.iso
set root=(loop)
set iso_path="/archlinux-x86_64.iso"
set timeout=-1
EOF
    cat /x/boot/grub/loopback.cfg
} > /boot/grub/grub.cfg

clear
echo -e "Use 'reboot' to start installation.\nAfter reboot, continue installation in the VNC.\nThe original grub is in /boot/grub/grub.cfg.bak\nWhen the memory is less than 384 MiB, you may need to replace the appropriate initrd."
