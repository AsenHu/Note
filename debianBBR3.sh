#!/bin/bash

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

source=deb.debian.org/debian
secSource=security.debian.org/debian-security
CFIP=na
port=$((RANDOM * 8 % 55535 + 10000))

case $(lscpu) in
    *avx512*)
        microArch=4
        ;;
    *avx2*)
        microArch=3
        ;;
    *sse4_2*)
        microArch=2
        ;;
    *)
        microArch=1
        ;;
esac

user=$(ls /home)

if [ "$(echo "$user" | wc -l)" != 1 ]
then
    echo "What's your username?"
    ls /home
    read -r user
fi
echo "Hello $user!"

echo "Set your public key for SSH."
read -r -p "Press Enter to continue..."
mkdir /home/"$user"/.ssh
nano /home/"$user"/.ssh/authorized_keys
chmod 600 /home/"$user"/.ssh/authorized_keys
chown "$user":"$user" /home/"$user"/.ssh/authorized_keys

echo "Are you in China? (y/n)"
read -r inChina
if [ "$inChina" = "y" ]
then
    echo "Setting up mirrors..."
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
mkdir -p /etc/netplan
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
                  on-link: true
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
} >> /etc/netplan/01-netcfg.yaml
sed -i 's/^/# /' /etc/netplan/01-netcfg.yaml
read -r -p "Press Enter to continue..."
nano /etc/netplan/01-netcfg.yaml
sed -i '/^#/d;/^$/d' /etc/netplan/01-netcfg.yaml
chmod 600 /etc/netplan/01-netcfg.yaml

echo "Let's start!"
read -r -p "Press Enter to continue..."

sed -i '/^#/!s/^/# /' /etc/apt/sources.list
mkdir -p /etc/apt/sources.list.d/
cat > /etc/apt/sources.list.d/init-sources.list << EOF
deb http://$source/ bookworm main contrib non-free non-free-firmware
deb http://$secSource/ bookworm-security main contrib non-free non-free-firmware
deb http://$source/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://$source/ bookworm main contrib non-free non-free-firmware
deb-src http://$secSource/ bookworm-security main contrib non-free non-free-firmware
deb-src http://$source/ bookworm-updates main contrib non-free non-free-firmware
EOF
apt update && apt install chrony sudo gpg curl openvswitch-switch ca-certificates netplan.io ufw systemd-resolved -y
curl https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list
apt update && apt install linux-xanmod-x64v$microArch -y

netplan apply

# 开启 bbr 和 TFO
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/01-bbr_tfo.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
EOF

# ssh
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/01-init.conf << EOF
Port $port
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
EOF

# chrony
cat > /etc/chrony/sources.d/init.sources << EOF
server time.cloudflare.com iburst nts
pool time.pool.aliyun.com iburst
EOF

# ufw
ufw disable
echo y | ufw reset
ufw default allow outgoing
ufw default deny incoming
ufw allow "$port"/tcp

# 放行 Cloudflare IP
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

echo y | ufw enable

# 系统自动更新与内核自动卸载
rm -rvf /root/updateData
mkdir -p /root/updateData
curl -o /root/updateData/kernalUpdate.sh https://raw.githubusercontent.com/AsenHu/Note/main/kernalUpdate.sh
chmod +x /root/updateData/kernalUpdate.sh
echo "$((RANDOM % 60)) $((RANDOM % 24)) * * * /bin/bash /root/updateData/kernalUpdate.sh" >> /var/spool/cron/crontabs/root
