#!/bin/bash

source=deb.debian.org/debian
secSource=security.debian.org/debian-security
CFIP=na
port=$((RANDOM * 8 % 55535 + 10000))

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

apt update
apt install -y curl sed gawk gzip rsync xz-utils virt-what

cd /
rm -rvf /x /rootfs.tar.xz
mkdir -p /x
path=$(curl https://images.linuxcontainers.org/meta/1.0/index-system | grep default | awk '-F;' '(( $1=="debian") && ( $3=="amd64" )) {print $NF}' | head -n 1)
curl -o ./rootfs.tar.xz "https://images.linuxcontainers.org/$path/rootfs.tar.xz"
tar -C /x -xvf rootfs.tar.xz

clear

echo "What's your username?"
ls /home
read -r user
if [ -z "$user" ]; then
    echo "ERROR:Username is empty"
    exit 1
fi
echo "Hello, $user"

echo "What's your password?"
read -r password
if [ -z "$password" ]; then
    echo "ERROR:Password is empty"
    exit 1
fi

echo "Set your public key for SSH."
read -r -p "Press Enter to continue..."
mkdir /x/home/"$user"
mkdir /x/home/"$user"/.ssh
nano /x/home/"$user"/.ssh/authorized_keys

echo "Are you in China? (y/N)"
read -r inChina
if [ "$inChina" = "y" ]; then
    source=mirrors.ustc.edu.cn/debian
    secSource=mirrors.ustc.edu.cn/debian-security
    CFIP=false
fi

echo -e "A random port number prevents scanning. How about \"$port\"?\nYou can enter a port or press Enter to accept the port.\nEnter \"more\" to get a new random port."
while true
do
    read -r tmp
    if [ "$tmp" == more ]
    then
        port=$((RANDOM * 8 % 55535 + 10000))
        echo "How about \"$port\"?"
    elif [ ! "$tmp" ] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
    then
        echo "\"$port\" is a good choice!"
        break
    elif [ "$tmp" -ge 1 ] && [ "$tmp" -le 65535 ]
    then
        port="$tmp"
        echo "\"$port\" is a good choice!"
        break
    else
        port=$((RANDOM * 8 % 55535 + 10000))
        echo "\"$tmp\" doesn't seem to be a port. How about \"$port\"?"
    fi
done

if [ "$CFIP" == na ]
then
    echo "Do you want to use Cloudflare CDN? (y/n)"
    read -r CFIP
    if [ "$CFIP" = "y" ]
    then
        CFIP=true
    else
        CFIP=false
    fi
fi

echo "Let's set your netplan!"
mkdir /x/etc/netplan
{
    cat <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 1.2.3.4/24
        - 1::1/64
      routes:
        - to: default
          via: 5.6.7.8
        - to: default
          via: 5::5
          on-link: true
      dhcp4: true
      dhcp6: true
      accept-ra: true
      ipv6-privacy: true
      nameservers:
        addresses:
          - 1.1.1.1
          - 2606:4700:4700::1111
          - 223.5.5.5
          - 2400:3200::1
EOF
ip a
ip route
ip -6 route
} > /x/etc/netplan/01-netcfg.yaml
sed -i 's/^/# /' /x/etc/netplan/01-netcfg.yaml
read -r -p "Press Enter to continue..."
nano /x/etc/netplan/01-netcfg.yaml
sed -i '/^#/d;/^$/d' /x/etc/netplan/01-netcfg.yaml
chmod 600 /x/etc/netplan/01-netcfg.yaml
rm -rvf /x/etc/resolv.conf
cat >> /x/etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 223.5.5.5
EOF

echo "Let's start!"
read -r -p "Press Enter to continue..."

sed -i '/^#/!s/^/# /' /x/etc/apt/sources.list
mkdir -p /x/etc/apt/sources.list.d/
cat >> /x/etc/apt/sources.list.d/init-sources.list << EOF
deb http://$source/ bookworm main contrib non-free non-free-firmware
deb http://$secSource/ bookworm-security main contrib non-free non-free-firmware
deb http://$source/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://$source/ bookworm main contrib non-free non-free-firmware
deb-src http://$secSource/ bookworm-security main contrib non-free non-free-firmware
deb-src http://$source/ bookworm-updates main contrib non-free non-free-firmware
EOF

rsync -a -v --delete-after --ignore-times --exclude="/dev" --exclude="/proc" --exclude="/sys" --exclude="/x" --exclude="/run" /x/* /
rm -rvf /x /rootfs.tar.xz

echo -e "$password\n$password\n" | passwd

apt update
apt install openssh-server openvswitch-switch netplan.io ca-certificates sudo ufw systemd-resolved -y
apt upgrade -y

# 创建账户设置密码
echo -e "$password\n$password\n\n\n\n\n\ny" | adduser "$user"
chown -R "$user":"$user" /home/"$user"
chmod 600 /home/"$user"/.ssh/authorized_keys

# visudo
chmod 777 /etc/sudoers
echo "$user ALL=(ALL:ALL) ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

# SSH
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/01-init.conf << EOF
Port $port
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
EOF

# 设置时区
timedatectl set-timezone Asia/Shanghai

# 防火墙操作
ufw disable
echo y | ufw reset
ufw default allow outgoing
ufw default deny incoming
ufw allow "$port"/tcp

# 全锥

range=$(sysctl -n net.ipv4.ip_local_port_range)
start_port=$(echo $range | cut -d ' ' -f 1)
end_port=$(echo $range | cut -d ' ' -f 2)
sudo ufw allow "$start_port:$end_port/udp"

# 放行 Cloudflare

if [ "$CFIP" == true ]
then

ufw allow from 173.245.48.0/20 to any port 443 proto tcp
ufw allow from 103.21.244.0/22 to any port 443 proto tcp
ufw allow from 103.22.200.0/22 to any port 443 proto tcp
ufw allow from 103.31.4.0/22 to any port 443 proto tcp
ufw allow from 141.101.64.0/18 to any port 443 proto tcp
ufw allow from 108.162.192.0/18 to any port 443 proto tcp
ufw allow from 190.93.240.0/20 to any port 443 proto tcp
ufw allow from 188.114.96.0/20 to any port 443 proto tcp
ufw allow from 197.234.240.0/22 to any port 443 proto tcp
ufw allow from 198.41.128.0/17 to any port 443 proto tcp
ufw allow from 162.158.0.0/15 to any port 443 proto tcp
ufw allow from 104.16.0.0/13 to any port 443 proto tcp
ufw allow from 104.24.0.0/14 to any port 443 proto tcp
ufw allow from 172.64.0.0/13 to any port 443 proto tcp
ufw allow from 131.0.72.0/22 to any port 443 proto tcp

ufw allow from 2400:cb00::/32 to any port 443 proto tcp
ufw allow from 2606:4700::/32 to any port 443 proto tcp
ufw allow from 2803:f800::/32 to any port 443 proto tcp
ufw allow from 2405:b500::/32 to any port 443 proto tcp
ufw allow from 2405:8100::/32 to any port 443 proto tcp
ufw allow from 2a06:98c0::/29 to any port 443 proto tcp
ufw allow from 2c0f:f248::/32 to any port 443 proto tcp

fi

echo "================================================================"
echo -e "Finish."
echo -e "You are setting username : ${user}"
echo -e "You are setting password : $password for ${user}"
echo -e "You are setting port : $port"
echo -e "The firewall is enabled, please change the port after this session ends."
echo -e "Use 'reboot' to finish installation."

# 开启防火墙
echo y | ufw enable
