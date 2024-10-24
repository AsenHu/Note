#!/bin/bash

mkdir -p /tmp/debbr3

#### 问卷收集信息 ----------------------------------------------------------------

# 用户名 user
user=$(ls /home)
if [ "$(echo "$user" | wc -l)" != 1 ]
then
    echo "What's your username?"
    ls /home
    read -r user
fi
echo "Hello $user!"

# 密码 passwd
echo "Please enter your password"
read -r passwd

# 密钥 key
echo "Set your public key for SSH."
read -r -p "Press Enter to continue..."
nano /tmp/debbr3/authorized_key
key=$(< /tmp/debbr3/authorized_key)

# 端口 port
echo "Please enter a port, enter more to change one."
port=$((RANDOM * 8 % 55535 + 10000))
echo "$port"
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

# 镜像源 mirror
echo "Please enter mirrors"
echo "deb.debian.org"
echo "mirrors.tuna.tsinghua.edu.cn"
echo "mirrors.ustc.edu.cn"
echo "mirrors.tencent.com"
echo "mirrors.aliyun.com"
echo "mirrors.cloud.aliyuncs.com !!!!Intranet Source!!!!"
echo "mirrors.tencentyun.com !!!!Intranet Source!!!!"
read -r mirror

# 完成信息收集
echo "Let's start!"
read -r -p "Press Enter to continue..."

#### 准备工作 -------------------------------------------------------------------

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

curl -o /tmp/debbr3/kernalUpdate.sh https://raw.githubusercontent.com/AsenHu/Note/main/kernalUpdate.sh

#### 开始操作系统 ----------------------------------------------------------------

# 创建账户
if getent passwd "$user" > /dev/null
then
    useradd --create-home "$user"
fi

# 修改密码
echo "$passwd" | passwd --stdin "$user"

# 设置密钥
mkdir -p /home/"$user"/.ssh
echo "$key" > /home/"$user"/.ssh/authorized_keys
chmod 700 /home/"$user"/.ssh
chmod 600 /home/"$user"/.ssh/authorized_keys
chown "$user":"$user" /home/"$user"/.ssh -R

# 换源
sed -i '/^#/!s/^/# /' /etc/apt/sources.list
mkdir -p /etc/apt/sources.list.d/
cat > /etc/apt/sources.list.d/init-sources.list << EOF
deb http://$mirror/debian bookworm main contrib non-free non-free-firmware
deb http://$mirror/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://$mirror/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://$mirror/debian bookworm main contrib non-free non-free-firmware
deb-src http://$mirror/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://$mirror/debian bookworm-updates main contrib non-free non-free-firmware
EOF

# 安装软件包
apt update && apt install chrony sudo gpg curl ca-certificates -y

# 更换内核
curl https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg || xanmodKey | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list
apt update && apt install linux-xanmod-x64v$microArch -y

# sysctl
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-network.conf << EOF
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq_codel
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_tw_reuse = 1
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

# 内核更新脚本
rm -rvf /root/updateData
mkdir -p /root/updateData
mv -f /tmp/debbr3/kernalUpdate.sh /root/updateData/kernalUpdate.sh
chmod +x /root/updateData/kernalUpdate.sh

# 清理 tmp
rm -rvf /tmp/debbr3

#### 完成 提示信息 ---------------------------------------------------------------

echo -e "\n\n\n\nAll done!"
read -r -p "Press Enter to clear the screen..."

# 全锥
echo -e "\nFull cone port range"
sysctl -n net.ipv4.ip_local_port_range

# cron 内核更新
echo -e "\nAutomatic kernel updates via cron"
echo "$((RANDOM % 60)) $((RANDOM % 24)) * * * /bin/bash /root/updateData/kernalUpdate.sh"

echo -e "\nPlease complete the subsequent work (such as configuring the network) and restart the system."