#!/bin/bash

# 更新
apt update
apt upgrade -y

# 获取运行中和已安装最新内核版本
runVersion=$(dpkg -l | grep -E "image.*$(uname -r)" | awk '{print $2}' | head -n 1)
latestVersion=$(dpkg -l | grep -E "linux-image.+xanmod" | awk '{print $2}' | sort -Vr | head -n 1)

# 获取可以保证开机的内核版本
mkdir -p /root/updateData
fileRunVersion=$(< /root/updateData/runVersion)
fileBackupVersion=$(< /root/updateData/backupVersion)

# 如果保存的版本不存在，则使用当前版本
if ! dpkg -s "$fileRunVersion" >/dev/null 2>&1 
then
    fileRunVersion="$runVersion"
fi
if ! dpkg -s "$fileBackupVersion" >/dev/null 2>&1 
then
    fileBackupVersion="$runVersion"
fi
# 更新保存的版本
if [ "$fileRunVersion" != "$runVersion" ]; then
    fileBackupVersion="$fileRunVersion"
    fileRunVersion="$runVersion"
fi
echo "$fileRunVersion" > /root/updateData/runVersion
echo "$fileBackupVersion" > /root/updateData/backupVersion

# 启用新内核
if [ "$runVersion" != "$latestVersion" ]; then
    echo "$(date) update: $runVersion -> $latestVersion" >> /root/updateData/kernal.log
    /sbin/reboot
else
    # 卸载旧内核
    needPurge=$(dpkg -l | grep 'linux-image' | awk '{print $2}' | grep -v -E "$fileRunVersion|$fileBackupVersion" | tr '\n' ' ')
    if [ -n "$needPurge" ]
    then
        echo "$(date) purge: $needPurge" >> /root/updateData/kernal.log
        needPurgeCmd="apt purge -y $needPurge"
        $needPurgeCmd
    else
        echo "$(date) Nothing to do." > /root/updateData/lastCheck.log
    fi
fi
