#!/bin/bash

file_to_check="/root/bin/checkip.sh"
directory_to_check="/root/bin/"

# 检查目录是否存在
if [ -d "$directory_to_check" ]; then
    echo "目录 '$directory_to_check' 存在."
else
    echo "目录 '$directory_to_check' 不存在.主动创建ing..."
    mkdir $directory_to_check
fi

# 检查文件是否存在
if [ -e "$file_to_check" ]; then
    echo "文件 '$file_to_check' 存在."
else
    echo "文件 '$file_to_check' 不存在.主动创建ing..."
    touch $file_to_check
fi

echo '#!/bin/sh' > $file_to_check
echo '#登录失败次数大于10的ip' >> $file_to_check
echo 'IP=$(awk '\''/Failed/{print $(NF-3)}'\'' /var/log/secure | sort | uniq -c | awk '\''{if($1>10) print $2}'\'')' >> $file_to_check
echo 'hostdeny=/etc/hosts.deny' >> $file_to_check
echo 'for i in $IP' >> $file_to_check
echo 'do' >> $file_to_check
echo '  #如果ip不存在，则写入deny文件' >> $file_to_check
echo '  if [ ! $(grep $i $hostdeny) ]' >> $file_to_check
echo '  then' >> $file_to_check
echo '    echo "sshd:$i" >> $hostdeny' >> $file_to_check
echo '  fi' >> $file_to_check
echo 'done' >> $file_to_check

chmod 777 $file_to_check

# 添加计划任务到当前用户的 crontab 中
# 注意：确保你的脚本有足够的权限来修改当前用户的 crontab

# 下边的方法 覆盖与不覆盖选择一个执行
# 添加计划任务到 crontab(覆盖)
# echo "*/5 * * * * $file_to_check &>/dev/null" | crontab -

# 要添加的计划任务(不覆盖) --begin
crontab -l > /tmp/crontab_tmp
echo "*/5 * * * * $file_to_check &>/dev/null" >> /tmp/crontab_tmp
# 导入临时文件到 crontab 中
crontab /tmp/crontab_tmp
echo "Succ!!"

# 删除临时文件 --end
rm /tmp/crontab_tmp

# 重启cron服务
systemctl reload crond
systemctl restart crond