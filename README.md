# Note
一个 Bash 笔记本

# autoset

在用萌咖大佬的脚本 dd 完之后，自动创建用户设置密码还有防火墙这些玩意

```bash
# bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') <用户名> <密码> <Ubuntu 版本> <源> <是否在 443 只放行 CFIP> <公钥> <端口>
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') asen Asenyyds focal archive.ubuntu.com true "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGEpgwG92X5A1p6GrExP9URL6sDQYRcL1w2P9bB2FN4 20230619" 22
```

一种搭配萌咖大佬一键 dd 的使用方式
