#!/bin/bash

# 函数：检查命令是否成功执行
check_command() {
    if [ $? -ne 0 ]; then
        echo "命令执行失败: $1"
        exit 1
    fi
}

# 检查 Node.js、npm 和 PM2 是否已安装
check_installed() {
    command -v node >/dev/null 2>&1 && NODE_INSTALLED=true || NODE_INSTALLED=false
    command -v npm >/dev/null 2>&1 && NPM_INSTALLED=true || NPM_INSTALLED=false
    command -v pm2 >/dev/null 2>&1 && PM2_INSTALLED=true || PM2_INSTALLED=false
}

# 安装 Node.js 和 PM2
install_dependencies() {
    echo "正在更新软件包列表..."
    sudo apt update
    check_command "更新软件包列表失败"

    echo "正在安装 Node.js 和 PM2..."
    if ! curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -; then
        echo "添加 NodeSource 仓库失败，尝试备用方法..."
        if ! curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -; then
            echo "添加 NodeSource 仓库失败，退出。"
            exit 1
        fi
    fi

    if ! sudo apt-get install -y nodejs; then
        echo "安装 Node.js 失败，退出。"
        exit 1
    fi

    echo "Node.js 版本: $(node -v)"
    echo "npm 版本: $(npm -v)"

    # 检查 PM2 是否已安装
    if ! command -v pm2 &> /dev/null; then
        echo "PM2 未安装，正在安装..."
        if ! sudo npm install pm2 -g; then
            echo "通过 npm 安装 PM2 失败，退出。"
            exit 1
        fi
    else
        echo "PM2 已安装，跳过安装。"
    fi

    echo "PM2 版本: $(pm2 -v)"
}

# 主菜单循环
while true; do
    echo "华为云慎用！！！"
  
    echo "请选择命令:"
    echo "1. 下载配置环境并设置地址"
    echo "2. 启动验证器"
    echo "3. 停止并删除验证器"
    echo "4. 更新验证者（自动停止跟启动）"
    echo "5. 查看日志"
    echo "6. 创建 cysic 监控异常自动重启脚本----感谢作者0xlyc"
    echo "9. 删除验证器"
    echo "0. 退出"
    read -p "请输入命令: " command

    case $command in
        1)
            check_installed
            if [ "$NODE_INSTALLED" = false ] || [ "$NPM_INSTALLED" = false ] || [ "$PM2_INSTALLED" = false ]; then
                install_dependencies
            else
                echo "Node.js、npm 和 PM2 已安装，跳过安装。"
            fi
            echo "PM2 和配置验证器安装完成，返回主菜单..."

            # 提示用户输入奖励地址
            read -p "请输入你的实际奖励地址: " reward_address

            # 下载并配置验证器
            echo "正在下载并配置验证器..."
            if curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh -o ~/setup_linux.sh; then
                bash ~/setup_linux.sh "$reward_address"
            else
                echo "下载失败，请检查 URL 或网络连接。"
            fi
            ;;

        2)
            # 启动验证器
            if [ ! -f pm2-start.sh ]; then
                echo "正在创建 pm2-start.sh 脚本..."
                echo -e '#!/bin/bash\ncd ~/cysic-verifier/ && bash start.sh' > pm2-start.sh
                chmod +x pm2-start.sh
            fi

            echo "正在启动验证器..."
            if pm2 start ./pm2-start.sh --interpreter bash --name cysic-verifier; then
                echo "Cysic Verifier 启动完成，返回主菜单..."
            else
                echo "启动失败，请检查 PM2 和脚本。"
            fi
            ;;

        3)
            # 停止验证器
            echo "正在停止并删除验证器..."
            pm2 stop cysic-verifier
            #pm2 delete cysic-verifier
            echo "验证器已停止并删除，返回主菜单..."
            ;;

        4)
            # 更新配置文件
            #更新配置文件
            echo "正在停止验证器，3秒后执行更新。"
            pm2 stop cysic-verifier
            sleep 3
            sudo rm -rf ~/cysic-verifier/data
            curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/verifier_linux > ~/cysic-verifier/verifier
            curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/libdarwin_verifier.so > ~/cysic-verifier/libdarwin_verifier.so
            echo "更新完成，5秒后将重新启动验证器。"
            sleep 5
            chmod +x ~/cysic-verifier/verifier
            pm2 start cysic-verifier
            ;;

        5)
            # 查看验证器日志
            echo "正在查看验证器日志..."
            pm2 logs cysic-verifier
            echo "按 Ctrl+C 退出日志查看。"
            ;;

        6)
            # 创建 cysic 监控异常自动重启脚本
            echo "正在下载监控脚本---作者0xlyc"
            curl -O https://raw.githubusercontent.com/mang1024/mang/refs/heads/main/cyjk.js
            if [ $? -eq 0 ]; then
              echo "2秒后执行脚本操作"
              sleep 2
              pm2 start ./cyjk.js --name "cyjk"
              echo "查看异常重启日志请使用命令 pm2 logs cyjk"
              pm2 save
              sleep 5
            else
              echo "下载失败，请检查网络连接或URL是否正确"
            fi
            ;;
	9)
	    # 提示用户确认
	    read -p "是否确定删除验证器? (y/n): " confirm

	    # 检查用户输入
	    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    		echo "正在执行 'pm2 logs cysic-verifier'..."
    		pm2 delete cysic-verifier
	    else
    		echo "操作已取消。"
	    fi

        0)
            # 退出脚本
            echo "退出脚本..."
            echo "退出程序。"
            exit 0
            ;;
        *)
            echo "无效选项，请选择有效的菜单选项。"
            echo "无效的命令编号，请重新输入。"
            ;;
    esac
done
