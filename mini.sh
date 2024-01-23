#!/bin/bash

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

dir_to_hd() {
    local dir dev
    dir=$1
    dev=$(df --output=source "$dir" | tail -1)  # Get the device name of the filesystem containing the directory
    dev_to_hd "$dev"
}

dev_to_hd() {
    local dev hd disk part disk_num part_num
    dev=$1
    hd=${dev#/dev/sd}  # Remove /dev/sd
    disk=${hd%[0-9]*}  # Remove partition number
    part=${hd#"$disk"}   # Remove disk letter

    disk_num=$(printf "%d" "'$disk")  # Convert disk letter to ASCII code
    disk_num=$((disk_num - 97))  # Convert ASCII code to disk number (a -> 0, b -> 1, ...)

    part_num=$((part - 1))  # Convert partition number (1 -> 0, 2 -> 1, ...)

    echo "(hd$disk_num,$part_num)"
}

rm -rvf /x /mini.iso
curl -o /mini.iso https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso

mkdir -p /x
mount -o loop /mini.iso /x

hd=$(dir_to_hd /)

{
    cat << EOF
loopback loop $hd
set timeout=-1
set root=(loop)
EOF
    cat /x/boot/grub/grub.cfg
} > /boot/grub/grub.cfg

clean
echo -e "Use 'reboot' to start installation.\nAfter reboot, continue installation in the VNC."
