# Note
一个 Bash 笔记本

# autoset

在用萌咖大佬的脚本 dd 完之后，自动创建用户设置密码还有防火墙这些玩意

```bash
# bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/autoset.sh') <用户名> <密码> <Ubuntu 版本> <源> <是否在 443 只放行 CFIP> <公钥> <端口>
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/autoset.sh') asen Asenyyds focal archive.ubuntu.com true "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGEpgwG92X5A1p6GrExP9URL6sDQYRcL1w2P9bB2FN4 20230619" 22
```

一种搭配萌咖大佬一键 dd 的使用方式

```bash
p=$((RANDOM * 8 % 55535 + 10000));echo -e "Prot = $p\nType $p to continue";read -r tmp;if [ "$tmp" == "$p" ];then bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -u 20.04 -v 64 -a --mirror 'http://archive.ubuntu.com/ubuntu/' -cmd "$(echo "bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/autoset.sh') asen Asenyyds focal archive.ubuntu.com true 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGEpgwG92X5A1p6GrExP9URL6sDQYRcL1w2P9bB2FN4 20230619' $p" |base64 |tr -d "\n")";else echo "Operation canceled";fi;
```

它会先随机一个 10000-65535 之间的端口告诉你，并且把它设为 dd 后的端口，它还会新建用户 asen 密码为 Asenyyds 换源为 archive.ubuntu.com 放行 cloudflare ip 在 443/tcp 并开启公钥登录

其实就是两个命令套娃（

dd Debian 12

```
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 12 -v 64 -a --mirror 'http://deb.debian.org/debian/'
```
