#!/usr/bin/env bash

if [ "$1" ]
then
export http_proxy=$1
export https_proxy=$1
export frp_proxy=$1
export all_proxy=$1
fi

cd ~ || exit

#需要加入的插件
mod=(github.com/caddy-dns/cloudflare)

########################下面是代码不是配置文件不要动它########################
apt update && apt install curl wget -y
export PATH="$PATH:/usr/local/go/bin"

xcaddyCheck(){
    xcaddyLatName=$(wget -qO- -t1 -T2 "https://api.github.com/repos/caddyserver/xcaddy/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    xcaddyLatest=$(echo "$xcaddyLatName" | tr -cd "0-9")
    xcaddyVerName=$(xcaddy version | awk -F " " '{print $1}')
    xcaddyNow=$(echo "$xcaddyVerName" | tr -cd "0-9")
    if [ ! \( "$xcaddyLatest" = "$xcaddyNow" \) ]
    then
    echo "xcaddy当前版本为 $xcaddyVerName  最新版本为 $xcaddyLatName  准备更新xcaddy"
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    rm -rf /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-xcaddy.list
    apt update
    apt install xcaddy
    else
    echo "xcaddy $xcaddyVerName 已经是最新的版本了"
    fi
}
unset par

#获取caddy最新版本
caddyLatName=$(wget -qO- -t1 -T2 "https://api.github.com/repos/caddyserver/caddy/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
caddyLatest=$(echo "$caddyLatName" | tr -cd "0-9")

#获取本地caddy版本
caddyVerName=$(caddy version | awk -F " " '{print $1}')
caddyNow=$(echo "$caddyVerName" | tr -cd "0-9")

#判断是否更新 否则退出 是则继续
if [ ! \( "$caddyLatest" = "$caddyNow" \) ]
then
echo "Caddy当前版本为 $caddyVerName  最新版本为 $caddyLatName  准备构建Caddy"
#获取go最新版本
goLatest=$(curl -s  https://studygolang.com/dl |  sed -n '/dl\/golang\/go.*\.linux-amd64\.tar\.gz/p' | sed -n '1p' | sed -n '/1/p' | awk 'BEGIN{FS="\""}{print $4}' | awk 'BEGIN{FS="/"}{print $4}' | tr -cd "0-9")

#获取本地go版本
goNow=$(go version | tr -cd "0-9")

#判断是否更新 是则执行
if [ ! \( "$goLatest" = "$goNow" \) ]
then
echo "Go当前版本为 $(go version)  最新版本为 $goLatest  准备更新Go"
#执行go更新程序
goName=$(curl -s  https://studygolang.com/dl |  sed -n '/dl\/golang\/go.*\.linux-amd64\.tar\.gz/p' | sed -n '1p' | sed -n '/1/p' | awk 'BEGIN{FS="\""}{print $4}' | awk 'BEGIN{FS="\/golang\/"}{print $2}')
goUrl="https://go.dev/dl/$goName"
wget "$goUrl"
rm -rf /usr/local/go
tar -C /usr/local -xzf "$goName"
rm -rf "$goName"
echo "Go已更新至 $(go version)"
else
echo "Go已经是最新的版本了 $(go version)"
fi
xcaddyCheck
echo "开始构建Caddy"
#生成Caddy构建参数
echo "你添加的模组为:"
for i in "${mod[@]}"
do
par=" --with $i$par"
echo "$i"
done
echo
par="xcaddy build$par"
#xcaddy构建caddy
$par

#后话操作
mv ./caddy /usr/bin/
groupadd --system caddy
useradd --system --gid caddy --create-home --home-dir /var/lib/caddy --shell /usr/sbin/nologin --comment "Caddy web server" caddy
wget -L -O caddy.service https://raw.githubusercontent.com/caddyserver/dist/master/init/caddy.service
mv ./caddy.service /usr/lib/systemd/system/caddy.service
systemctl daemon-reload
systemctl enable --now caddy

caddyVerName=$(caddy version | awk -F " " '{print $1}')
echo "Caddy已更新至 $caddyVerName"

else
echo "Caddy $caddyVerName 已经是最新的版本了"
fi

systemctl enable caddy
systemctl start caddy
