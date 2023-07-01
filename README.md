# Note
一个 Bash 笔记本

# uidd

在用萌咖大佬的脚本 dd 完之后，自动创建用户设置密码还有防火墙这些玩意

它现在是交互式的了，因为我发现传参的方式真的太不方便了

```bash
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/uidd.sh')
```

不过你可以给他设置默认值，如果同级目录下有 `env.sh`，就会用 `env.sh` 覆盖默认的值，这意味着你可以这样写来实现类似传参的玩法。

```bash
echo -e "name=asen\npass=Asenyyds" > env.sh && bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/uidd.sh')
```

它会将默认的用户名设置为 `asen`，默认密码设置为 `Asenyyds`

~~`$2` 是传到萌咖脚本上的，用于特殊用途，比如你的服务器是纯 IPv6 的，萌咖脚本会获取不到你的 IP 地址，这时候你就要附加类似这样的东西 `bash uidd.sh "" "--ip-addr 2001:bc8:62c:233::1/64 --ip-gate 2001:bc8:62c:233:: --ip-mask 255.255.255.254 --ip-dns 2001:67c:2b0::4"` 来给萌咖指定 IP 网关 DNS 啥的，让它可以 dd 系统。这里 `$1` 如果你啥都不想写就写 `""`，不然 `$2` 就会变成 `$1`~~ 我还用不上这个东西，有需要的人 Pull Request 吧

# LXCuidd

自己搓了个 LXC 的重装脚本，原理是替换用户空间。它和 `uidd.sh` 一样使用 `env.sh` 来传参

```bash
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/LXCuidd.sh')
```

dd Debian 12

```
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 12 -v 64 -a --mirror 'http://deb.debian.org/debian/'
```
