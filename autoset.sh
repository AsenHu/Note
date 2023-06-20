#!/usr/bin/env bash

name="$1"
pass="$2"
port="$7"
swap="512M"
version="$3"
sources="$4"
cfon="$5"
key="$6"

#换源
echo -e "deb http://$sources/ubuntu/ $version main restricted universe multiverse\ndeb http://$sources/ubuntu/ $version-security main restricted universe multiverse\ndeb http://$sources/ubuntu/ $version-updates main restricted universe multiverse\ndeb-src http://$sources/ubuntu/ $version main restricted universe multiverse\ndeb-src http://$sources/ubuntu/ $version-security main restricted universe multiverse\ndeb-src http://$sources/ubuntu/ $version-updates main restricted universe multiverse" > /etc/apt/sources.list

#linux-image-cloud-amd64
apt update && apt install chrony -y && apt upgrade -y

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
sed -i "/^[^#]*Port.*/d" /etc/ssh/sshd_config
sed -i '/^[^#]*PermitRootLogin.*/d' /etc/ssh/sshd_config
sed -i '/^[^#]*PubkeyAuthentication.*/d' /etc/ssh/sshd_config
sed -i '/^[^#]*PasswordAuthentication.*/d' /etc/ssh/sshd_config
{
    echo "Port $port"
    echo "PermitRootLogin no"
    echo "PubkeyAuthentication yes"
    echo "PasswordAuthentication no"
} >> /etc/ssh/sshd_config
mkdir -p /home/"$name"/.ssh/
echo "$key" > /home/"$name"/.ssh/authorized_keys
chown -R "$name" /home/"$name"/
chmod 600 /home/"$name"/.ssh/authorized_keys

#设置时区
timedatectl set-timezone Asia/Shanghai

# 自动对时
sed -i "/^[^#]*dhcp.*/d" /etc/chrony/chrony.conf
sed -i '/^pool.*/d' /etc/chrony/chrony.conf
sed -i '/^peer.*/d' /etc/chrony/chrony.conf
sed -i '/^server.*/d' /etc/chrony/chrony.conf

echo server time.cloudflare.com iburst nts >> /etc/chrony/chrony.conf

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

# 放行 Cloudflare

if [ "$cfon" == true ]
then

sudo ufw allow from 173.245.48.0/20 to any port 443 proto tcp
sudo ufw allow from 103.21.244.0/22 to any port 443 proto tcp
sudo ufw allow from 103.22.200.0/22 to any port 443 proto tcp
sudo ufw allow from 103.31.4.0/22 to any port 443 proto tcp
sudo ufw allow from 141.101.64.0/18 to any port 443 proto tcp
sudo ufw allow from 108.162.192.0/18 to any port 443 proto tcp
sudo ufw allow from 190.93.240.0/20 to any port 443 proto tcp
sudo ufw allow from 188.114.96.0/20 to any port 443 proto tcp
sudo ufw allow from 197.234.240.0/22 to any port 443 proto tcp
sudo ufw allow from 198.41.128.0/17 to any port 443 proto tcp
sudo ufw allow from 162.158.0.0/15 to any port 443 proto tcp
sudo ufw allow from 104.16.0.0/13 to any port 443 proto tcp
sudo ufw allow from 104.24.0.0/14 to any port 443 proto tcp
sudo ufw allow from 172.64.0.0/13 to any port 443 proto tcp
sudo ufw allow from 131.0.72.0/22 to any port 443 proto tcp

sudo ufw allow from 2400:cb00::/32 to any port 443 proto tcp
sudo ufw allow from 2606:4700::/32 to any port 443 proto tcp
sudo ufw allow from 2803:f800::/32 to any port 443 proto tcp
sudo ufw allow from 2405:b500::/32 to any port 443 proto tcp
sudo ufw allow from 2405:8100::/32 to any port 443 proto tcp
sudo ufw allow from 2a06:98c0::/29 to any port 443 proto tcp
sudo ufw allow from 2c0f:f248::/32 to any port 443 proto tcp

fi

echo -e "Finish."
echo -e "You are setting username : ${name}"
echo -e "You are setting password : $pass for ${name}"
echo -e "You are setting port : $port"
echo -e "The firewall is enabled, please change the port after this session ends."

rm -rf ./autoset.sh

#开启防火墙断开当前连接
echo y | sudo ufw enable
sudo reboot
