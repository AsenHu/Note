#!/usr/bin/env bash

name="asen"
pass="Asenyyds"
port=$((RANDOM * 8 % 55535 + 10000))
swap="512M"
version="focal"
# version="jammy"
sources="archive.ubuntu.com"
setnet="false"

#换源
echo -e "deb http://$sources/ubuntu/ $version main restricted universe multiverse\ndeb http://$sources/ubuntu/ $version-security main restricted universe multiverse\ndeb http://$sources/ubuntu/ $version-updates main restricted universe multiverse\ndeb-src http://$sources/ubuntu/ $version main restricted universe multiverse\ndeb-src http://$sources/ubuntu/ $version-security main restricted universe multiverse\ndeb-src http://$sources/ubuntu/ $version-updates main restricted universe multiverse" > /etc/apt/sources.list

#linux-image-cloud-amd64
apt update && apt upgrade -y

#开启bbr
echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.conf

#创建账户设置密码
echo -e "$pass\n$pass\n\n\n\n\n\ny" | adduser "$name"
#echo -e "$pass\n$pass" | passwd "$name"

#visudo
chmod u+w /etc/sudoers
echo "$name ALL=(ALL:ALL) ALL" >> /etc/sudoers
chmod u-w /etc/sudoers

#端口 关root登录 开启密钥登录
sed -i "/#\?.*Port.*/d" /etc/ssh/sshd_config
sed -i '/#\?.*PermitRootLogin.*/d' /etc/ssh/sshd_config
sed -i '/#\?.*PubkeyAuthentication.*/d' /etc/ssh/sshd_config
sed -i '/#\?.*PasswordAuthentication.*/d' /etc/ssh/sshd_config
{
    echo "Port $port"
    echo "PermitRootLogin no"
    echo "PubkeyAuthentication yes"
    echo "PasswordAuthentication no"
} >> /etc/ssh/sshd_config
mkdir -p /home/$name/.ssh/
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGEpgwG92X5A1p6GrExP9URL6sDQYRcL1w2P9bB2FN4 20230619" > /home/$name/.ssh/authorized_keys
chown -R "$name" /home/$name/
chmod 600 /home/$name/.ssh/authorized_keys

#设置时区
timedatectl set-timezone Asia/Shanghai

# 不复制网卡文件
if [ "$setnet" == "true" ]
then
mkdir -p /etc/netplan/
echo "$(<./netcfg.yaml)" > /etc/netplan/01-netcfg.yaml
fi

#设置 swap
swapoff /swapfile
rm -rf /swapfile
fallocate -l "$swap" /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

#防火墙操作
sudo ufw disable
echo y | sudo ufw reset
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow "$port"/tcp

# 不放行 Cloudflare

echo -e "Finish."
echo -e "You are setting username : ${name}"
echo -e "You are setting password : $pass for ${name}"
echo -e "You are setting port : $port"
echo -e "The firewall is enabled, please change the port after this session ends."

rm -rf ./autoset.sh

#开启防火墙断开当前连接
echo y | sudo ufw enable
sudo reboot
