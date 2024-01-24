# Note
一个 Bash 笔记本

# mini.sh

Debian 12 一键 VNC 全手动安装

```shell
bash <(curl https://raw.githubusercontent.com/AsenHu/Note/main/mini.sh -L -q --retry 5 --retry-delay 10 --retry-max-time 60)
```

本质就是把 debian 安装 iso 下载到本地然后引导启动

# debianBBR3

自用系统初始化脚本

```shell
bash <(curl https://raw.githubusercontent.com/AsenHu/Note/main/debianBBR3.sh -L -q --retry 5 --retry-delay 10 --retry-max-time 60)
```

可以方便的设置密钥，端口，防火墙，换内核，开 bbr3 这些操作，通常搭配 mini.sh 使用。建议阅读代码看看它到底会做什么再用。

# LXCuidd

自己搓了个 LXC 的重装脚本，原理是替换用户空间。

```shell
bash <(curl 'https://raw.githubusercontent.com/AsenHu/Note/main/LXCuidd.sh' -L -q --retry 5 --retry-delay 10 --retry-max-time 60)
```

# kernalUpdate

自动更新内核（写死 xanmod 内核了）并卸载旧内核。（不会全卸载，每次更新时，上次正常启动的内核不会被卸载，直到本次更新完成的内核被下次更新的新内核替换时才会被卸载）

```shell
apt update
apt install cron -y
rm -rvf /root/updateData
mkdir -p /root/updateData
curl -o /root/updateData/kernalUpdate.sh https://raw.githubusercontent.com/AsenHu/Note/main/kernalUpdate.sh -L -q --retry 5 --retry-delay 10 --retry-max-time 60
chmod +x /root/updateData/kernalUpdate.sh
echo "$((RANDOM % 60)) $((RANDOM % 24)) * * * /bin/bash /root/updateData/kernalUpdate.sh" >> /var/spool/cron/crontabs/root
```

# 获取一个一天中随机一个时间的 crontab

```
echo "$((RANDOM % 60)) $((RANDOM % 24)) * * *"
```
