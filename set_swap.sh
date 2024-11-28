#!/bin/bash

# 获取用户输入的 Swap 文件大小（单位：GB）
read -p "请输入 swap 文件的大小（单位：GB）: " swap_size

# 检查输入是否为有效数字
if ! [[ "$swap_size" =~ ^[0-9]+$ ]]; then
    echo "无效输入！请输入一个正整数。"
    exit 1
fi

# 显示设置的 Swap 文件大小
echo "您输入的 swap 大小是 ${swap_size}GB。"

# 检查并创建目录 /swap
if [ ! -d "/swap" ]; then
    sudo mkdir /swap
    echo "目录 /swap 创建成功！"
else
    echo "目录 /swap 已存在，跳过创建。"
fi

# 使用 dd 命令创建 swap 文件（块大小 bs=128M）
echo "正在创建 ${swap_size}GB 的 swap 文件..."
sudo dd if=/dev/zero of=/swap/swapfile bs=128M count=$((swap_size * 8)) status=progress conv=fdatasync

# 检查 dd 命令是否成功
if [ $? -ne 0 ]; then
    echo "错误：swap 文件创建失败。"
    exit 1
fi

# 检查文件是否创建成功
if [ ! -f /swap/swapfile ] || [ ! -s /swap/swapfile ]; then
    echo "错误：swap 文件创建失败，文件大小为 0 或未创建。"
    exit 1
fi

# 设置 swap 文件权限为 600
echo "设置 swap 文件权限为 600..."
sudo chmod 600 /swap/swapfile

# 格式化 swap 文件
echo "正在格式化 swap 文件..."
sudo mkswap /swap/swapfile

# 启用 swap 文件
echo "启用 swap 文件..."
sudo swapon /swap/swapfile

# 永久挂载 swap 文件到 /etc/fstab
echo "更新 /etc/fstab 以便在系统重启后自动挂载 swap 文件..."
if ! grep -q "/swap/swapfile" /etc/fstab; then
    echo "/swap/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
else
    echo "swap 文件条目已经存在于 /etc/fstab 中。"
fi

echo "Swap 文件设置完成！"

