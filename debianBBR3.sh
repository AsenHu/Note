#!/bin/bash

curl() {
    # Copy from https://github.com/XTLS/Xray-install
    if ! $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@";then
        echo "ERROR:Curl Failed, check your network"
        exit 1
    fi
}

xanmodKey() {
    cat << EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQENBFhxW04BCAC61HuxBVf1XJiQjXu/DSAtVcnuK38geDoDjcqFtHskFy32NgJG
X118EFNym6noF+oibaSftI9yjHthWvMnYZ/+DPwd7YZhbAjBvxMIQCsP6cFVxrgc
VV8g+uh4TCfbpalDBFoncRhQCgkmDN9Vd4kIWRh6BHJuzpKB/h2KxUHZVEKgWlK2
dR1xUtbrc+kp8gLwPbxTgC3tZ4x2uMMMlnbyCMSRa5oJ/AvoW4W1XphKL9ivsFHM
PSQkUBDvgv2RPw+0XBxPy8SYE0r0onx0ZIpjJRTODt3bSV6/0owwlpNogV9bT8HY
kl3+w3mTwax6S1akHZuJtLkZS0uUBz1BHt5bABEBAAG0IVhhbk1vZCBLZXJuZWwg
PGtlcm5lbEB4YW5tb2Qub3JnPokBNwQTAQgAIQUCWHFbTgIbAwULCQgHAgYVCAkK
CwIEFgIDAQIeAQIXgAAKCRCG99Ce5zTmIwTmB/9/S4rmwU6efDgEaBDwBDbOfLBA
P2+kDpabjG4K+V4NSvDqlPN49KrI7C21jHghAa2VuTPbSZVQ9ziUd5DjX9OuXov8
CYVG+rrlG1UadHS8SBpgw0gNylEvo9/U6u0hl8mrbVOlpzu+eE+e4cMTHax2y580
fC2xmnM8wKgyRFEyVc6ilWU+UNTAeUFlg0YfU3cV1Ut4DzVFfamtNYg0p7Q/9MSy
VgFpt5C2U5prk4wi++51OgrtaNhMrUhzYXLINWVF6IrXhQ+mkI/FWXUZ0oyVo55v
+dQzuds/gos90q+tKyE514pYAmwQSftSjf+RmHOMpPQyMZZKSywrz4vlfveDuQEN
BFhxW04BCACs5bXq73MDb2+AsvNL2XkkbnzmE4K3k0gejB9OxrO+puAZn3wWyYIk
b0Op8qVUh+/FIiW/uFfmdFD8BypC3YkCNfg6e74f5TT3qQciccpMGy62teo3jfhT
T8E1OL1i76ALq7eNbByJKiKLBrTUDM6BDIeRZBWXQMase4+aqUAP47Kd/ByPsmCh
/pzb6yPdDPKwkspELssdPXYI7enddjQsCPoBko0j8CTPgKqMTeCuKMXCtD2gtRBN
eoVj4cbjZoZvBh8oJktzbYA8FX8eKdxIXhSP9MoVOPSWhxIQdwzkzUPK+0vUV8jA
NBTnGOkrRJPOHGPJWFWnTUGrzvcwi7czABEBAAGJAR8EGAEIAAkFAlhxW04CGwwA
CgkQhvfQnuc05iMIswgAmzSpCHFGKdkFLdC673FidJcL8adKFTO5Mpyholc5N8vG
ROJbpso+DpssF14NKoBfBWqPRgHxYzHakxHiNf0R2+EEwXH3rblzpx3PXzB0OgNe
T9T0UStrGgc9nZ8nZVURHZZ2z5zakEWS+rB2TiSxz3YArR3wiTHQW49G09uZvfp6
5Mim2w+eUxbQ689eT0DlDI1d2eDP/j5lrv1elsg3kBE2Awzdvi8DdGUpMFrSsYJw
WS85uZrwbeAs/nPO62wNIvAbbRsWnDg3AV3vc02eRvy52tTBY1W/67N02M4AxgPd
ukDDFZMifwa03yTHD/a57O4dFOnzsEVojBnbzQ7W7w==
=HKlF
-----END PGP PUBLIC KEY BLOCK-----
EOF
}

curl -o /tmp/kernalUpdate.sh https://raw.githubusercontent.com/AsenHu/Note/main/kernalUpdate.sh

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
chmod 700 /home/"$user"/.ssh
chmod 600 /home/"$user"/.ssh/authorized_keys
chown "$user":"$user" /home/"$user"/.ssh -R

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
curl https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg || xanmodKey | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list
apt update && apt install linux-xanmod-x64v$microArch -y

netplan apply

# 开启 bbr 和 TFO
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-network.conf << EOF
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc = fq_pie
net.ipv4.tcp_congestion_control = bbr
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

# 全锥

range=$(sysctl -n net.ipv4.ip_local_port_range)
start_port=$(echo $range | cut -d ' ' -f 1)
end_port=$(echo $range | cut -d ' ' -f 2)
sudo ufw allow "$start_port:$end_port/udp"

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
mv -f /tmp/kernalUpdate.sh /root/updateData/kernalUpdate.sh
chmod +x /root/updateData/kernalUpdate.sh
echo "$((RANDOM % 60)) $((RANDOM % 24)) * * * /bin/bash /root/updateData/kernalUpdate.sh" >> /var/spool/cron/crontabs/root
