#!/bin/bash

mkdir -p /tmp/LXCarch

pacman -Syu curl gawk tar xz nano ca-certificates rsync

clear

#### 问卷收集信息 ----------------------------------------------------------------

# 生成问卷文件
cat > /tmp/LXCarch/questionnaire.toml << EOF
# Please enter your password
# passwd = "NekoIsTheBest"
passwd = ""

# Set your public key for SSH (multi-line supported, place your key between the markers)
key = """
# ed25519 ABCD1234 example
# comment will be remove automatically
"""

# Please enter a port number for SSH
port = $((RANDOM * 8 % 55535 + 10000))

# Please enter mirrors
# You can choose from the following mirrors or enter your own:
# mirrors.kernel.org
# mirrors.tuna.tsinghua.edu.cn
# mirrors.ustc.edu.cn
# mirrors.tencent.com
# mirrors.aliyun.com
# mirrors.cloud.aliyuncs.com !!!!Intranet Source!!!!
# mirrors.tencentyun.com !!!!Intranet Source!!!!
mirror = "https://cloudflaremirrors.com/archlinux"
EOF

# 打开问卷供用户编辑
nano /tmp/LXCarch/questionnaire.toml

# 读取用户输入
passwd=$(grep '^passwd = ' /tmp/LXCarch/questionnaire.toml | cut -d'"' -f2)
port=$(grep '^port = ' /tmp/LXCarch/questionnaire.toml | cut -d' ' -f3)
mirror=$(grep '^mirror = ' /tmp/LXCarch/questionnaire.toml | cut -d'"' -f2)

# 验证用户输入
if [ -z "$passwd" ] || [ -z "$mirror" ]; then
    echo "Some required fields are missing. Please fill out the questionnaire completely."
    exit 1
fi

# 提取多行密钥
key=$(sed -n '/^key = """$/,/^"""$/p' /tmp/LXCarch/questionnaire.toml | sed '1d;$d' | sed '/^#/d')

# 验证端口
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "Invalid port number. Please enter a valid port between 1 and 65535."
    exit 1
fi

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

# 准备目录
rm -rf /x /rootfs.tar.xz
mkdir -p /x
path=$(curl https://images.linuxcontainers.org/meta/1.0/index-system | awk '-F;' '(( $1=="archlinux") && ( $3=="amd64" ) && ( $4=="default")) {print $NF}' | tail -n 1)
curl -o /rootfs.tar.xz "https://images.linuxcontainers.org/$path/rootfs.tar.xz"
tar -C /x -xf /rootfs.tar.xz

# 配置网络
cat /etc/resolv.conf > /x/etc/resolv.conf

# 配置源
cat << EOF > /etc/pacman.d/mirrorlist
Server = http://$mirror/\$repo/os/\$arch
EOF

# SSH
mkdir -p /x/etc/systemd/system/dropbear.service.d
cat > /x/etc/systemd/system/dropbear.service.d/SSH.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dropbear -F -P /run/dropbear.pid -R -s -p $port
EOF

# 有的没的（motd）
echo -e "✨ Welcome to Arch Linux, Adventurer! ✨\n\n(=^･ω･^=) Hi there! I'm Lilina Neko, your little guide through the Arch world! Let's make this system setup a fun adventure together!\n\n🌸 Quick Setup:\n- Need help? The Arch Wiki is your best friend: <https://wiki.archlinux.org/>\n- Keep your system updated with \`sudo pacman -Syu\`.\n\n⚙️ Some Quick Tips:\n- Install new packages using \`sudo pacman -S <package>\`.\n- Remove unnecessary packages with \`sudo pacman -R <package>\`.\n\n🌟 Today's Reminder:\n\"Arch Linux is as powerful as your curiosity! Keep exploring and enjoy the journey!\"\n\nHave a wonderful day, nya~ 🐾" > /x/etc/motd

#### 操作系统 -------------------------------------------------------------------

# 重写根目录
rsync -a --ignore-times --ignore-errors --delete --exclude={"/dev","/x","/run"} /x/ / 2>/dev/null
rm -rf /x

# 安装软件
pacman -Syu dropbear

# SSH 服务
systemctl enable dropbear

# 修改密码
echo "root:$passwd" | chpasswd

# 设置密钥
mkdir -p /root/.ssh
echo "$key" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chown root:root /root/.ssh -R

#### 完成 提示信息 ---------------------------------------------------------------

echo -e "\n\n\n\nAll done!"
read -r -p "Press Enter to clear the screen..."

clear

# 全锥
echo -e "\nFull cone port range"
sysctl -n net.ipv4.ip_local_port_range

echo -e "\nPlease complete the subsequent work (such as configuring the network) and restart the system."