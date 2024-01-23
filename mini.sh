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

rm -rvf /x /mini.iso
if $1
then
    mv -f "$1" /mini.iso
else
    curl -o /mini.iso https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso
fi

mkdir -p /x
mount -o loop /mini.iso /x

uuid=$(dir_to_uuid /)

{
    cat << EOF
search --no-floppy --set=root --fs-uuid $uuid
loopback loop /mini.iso
set timeout=-1
EOF
    cat /x/boot/grub/grub.cfg
} > /boot/grub/grub.cfg

clear
echo "uuid=$uuid"
echo -e "Use 'reboot' to start installation.\nAfter reboot, continue installation in the VNC."
