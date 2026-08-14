# 安装 Arch 操作系统检查单（BIOS）

该检查单皆在帮助用户在不支持 UEFI 启动的远程服务器安装 Arch Linux 并摘录安装时常用的 Wiki

## 1. 在 LiveCD 前

- [ ] 收集网络配置文件
    - [ ] IP 地址、子网掩码、路由配置方法（DHCP SLAAC 静态）
    - [ ] MAC 地址
    - [ ] 内网/服务商 DNS 地址
    - [ ] 内网/就近镜像源
- [ ] 设置 `copytoram=y`

```sh
# https://github.com/asenHu/note
bash <(curl https://raw.githubusercontent.com/AsenHu/Note/refs/heads/main/KVM/archlinux.sh)
bash <(curl https://raw.githubusercontent.com/AsenHu/Note/refs/heads/main/KVM/ultralite.sh)
```

## 2. 在 LiveCD

- [ ] 确认网络连接
- [ ] 准备 SSH 远程登录
- [ ] 确认该服务器确实不支持 UEFI

```sh
# https://wiki.archlinux.org/title/Installation_guide#Verify_the_boot_mode
cat /sys/firmware/efi/fw_platform_size
```

- [ ] 磁盘分区与格式化
    - [ ] `ef02` 分区（+1M）
    - [ ] Root 分区
    - [ ] 格式化 Root 分区
    - [ ] 挂载到 `/mnt` 以及挂载参数

```sh
mkfs.btrfs /dev/vda2

# https://wiki.archlinux.org/title/Btrfs#Compression
mount -o compress-force=zstd:15 /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@swap
# https://man.archlinux.org/man/arch-chroot.8#DESCRIPTION
## The target chroot-dir should be a mountpoint.
mount --bind /mnt/@ /mnt/@
mount -o compress-force=zstd:15,subvol=/ /dev/vda2 /mnt/@/mnt/root --mkdir

# https://wiki.archlinux.org/title/Btrfs#Swap_file
btrfs filesystem mkswapfile --size 2g --uuid clear /mnt/@swap/swapfile
swapon /mnt/@/mnt/root/@swap/swapfile
```

- [ ] 安装系统
    - [ ] 对镜像测速
    - [ ] 安装软件包

```sh
reflector --save /etc/pacman.d/mirrorlist --verbose -f 4 -c HK
pacstrap -K /mnt/@ base linux-zen msedit openssh grub
```

- [ ] 配置系统
    - [ ] Fstab
    - [ ] UTC 时间
    - [ ] 系统语言
    - [ ] 主机名与网络
    - [ ] 登陆凭证

```sh
genfstab -U /mnt/@
genfstab -U /mnt/@ >> /mnt/@/etc/fstab
arch-chroot /mnt/@

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

msedit /etc/locale.gen
# en_US.UTF-8 UTF-8
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

msedit /etc/hostname
msedit /etc/systemd/network/99-def.network
mkdir -p /etc/systemd/resolved.conf.d
msedit /etc/systemd/resolved.conf.d/cloudflare.conf

mkdir -p /root/.ssh
msedit /root/.ssh/authorized_keys
msedit /etc/ssh/sshd_config.d/20-security.conf

# https://wiki.archlinux.org/title/GRUB#GUID_Partition_Table_(GPT)_specific_instructions
grub-install --target=i386-pc /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable systemd-timesyncd systemd-networkd systemd-resolved sshd
```

```conf
# https://wiki.archlinux.org/title/Systemd-networkd#Configuration_files
# /etc/systemd/network/99-def.network
[Match]
MACAddress=18:97:07:26:48:65

[Address]
Address=2401:b60:e00e:72f9::/64

[Route]
Gateway=2401:b60:e00e::1
GatewayOnLink=yes

[Address]
Address=23.175.201.228/24

[Route]
Gateway=23.175.201.1
GatewayOnLink=yes
```

```conf
# https://wiki.archlinux.org/title/Systemd-resolved#DNS
# /etc/systemd/resolved.conf.d/cloudflare.conf
[Resolve]
DNS=2606:4700:4700::1111 2606:4700:4700::1001 1.1.1.1 1.0.0.1
Domains=~.
FallbackDNS=
DNSSEC=true
DNSOverTLS=yes
```

```conf
# https://wiki.archlinux.org/title/OpenSSH#Configuration_2
# https://wiki.archlinux.org/title/OpenSSH#Force_public_key_authentication
# /etc/ssh/sshd_config.d/20-security.conf
Port 39901
PasswordAuthentication no
AuthenticationMethods publickey
```

## 3. 系统安装后

- [ ] 检查 DNSSEC 与 DNS over TLS 正常工作

```sh
# https://wiki.archlinux.org/title/Systemd-resolved#DNS
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
resolvectl status
resolvectl query brokendnssec.net
resolvectl query baidu.com
resolvectl query nekos.chat
```

- [ ] 设置 sysctl

```sh
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/network.conf << EOF
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = cake
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_tw_reuse = 1
EOF
chmod 644 /etc/sysctl.d/network.conf
```

- [ ] 故障救援
    - [ ] 在磁盘根目录 `/boot-isos` 放置 Live CD
    - [ ] 追加启动项到 Grub
    - [ ] 测试

**Hint: 操作系统的根目录为 `/@`，因此你应该在 `/mnt/root/boot-isos` 下放置 ISO 文件**

```sh
# https://wiki.archlinux.org/title/Multiboot_USB_drive#Arch_Linux_monthly_release
# /etc/grub.d/40_custom
# 你应该追加到文件，而不是替换内容，不要忘记替换文件名
menuentry '[loopback]archlinux-2023.10.14-x86_64.iso' {
	set iso_path='/boot-isos/archlinux-2023.10.14-x86_64.iso'
	export iso_path
	search --set=root --file "$iso_path"
	loopback loop "$iso_path"
	root=(loop)
	configfile /boot/grub/loopback.cfg
	loopback --delete loop
}
```

```sh
# 修改生成菜单的配置文件后，再次生成 grub.cfg 启动菜单
grub-mkconfig -o /boot/grub/grub.cfg
```

- [ ] 检查云服务商的自动备份/快照并开启
