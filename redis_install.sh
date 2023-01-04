#!/bin/bash
# date : 2022.11.24
# Use：Centos 7 or openeluer
# Install Redis

#骚气颜色
show_str_Black() {
        echo -e "\033[30m $1 \033[0m"
}
show_str_Red() {
        echo -e "\033[31m $1 \033[0m"
}
show_str_Green() {
        echo -e "\033[32m $1 \033[0m"
}
show_str_Yellow() {
        echo -e "\033[33m $1 \033[0m"
}
show_str_Blue() {
        echo -e "\033[34m $1 \033[0m"
}
show_str_Purple() {
        echo -e "\033[35m $1 \033[0m"
}
show_str_SkyBlue() {
        echo -e "\033[36m $1 \033[0m"
}
show_str_White() {
        echo -e "\033[37m $1 \033[0m"
}

#获取当前时间
DATE=$(date +"%Y-%m-%d %H:%M:%S")
#获取当前主机名
HOSTNAME=$(hostname -s)
#获取当前用户
USER=$(whoami)
#获取当前内核版本参数
KERNEL=$(uname -r | cut -f 1-3 -d.)
redis_pass=$(date +%s | sha256sum | base64 | head -c 16)
ip=$(ifconfig | grep inet | grep netmask | head -n 1 | awk '{print $2}')

if [ -f "/etc/redhat-release" ]; then
        #获取当前系统版本
        SYSTEM=$(cat /etc/redhat-release)
elif [ -f "/etc/openEuler-release" ]; then
        SYSTEM=$(cat /etc/openEuler-release)
else
        show_str_Red "脚本不适配当前系统，请选择退出。谢谢！"
        exit 0
fi

log_file="logfile_$(date +"%Y-%m-%d-%H:%M:%S").log"

source_profile() {
        echo 'export PS1="\[\033[01;31m\]\u\[\033[00m\]@\033[01;32m\]\H\[\033[00m\][\[\033[01;33m\]\t\[\033[00m\]]:\[\033[01;34m\]\W\[\033[00m\]\n$"' >>/etc/profile
        source /etc/profile
}

#### log_correct函数打印正常的输出到日志文件
function log_correct() {
        DATE=$(date "+%Y-%m-%d %H:%M:%S")
        USER=$(whoami) ####那个用户在操作
        show_str_Green "${DATE} ${USER} $0 [INFO] $@" >>/root/$log_file
}

#### log_error函数打印错误的输出到日志文件
function log_error() {
        DATE=$(date "+%Y-%m-%d %H:%M:%S")
        USER=$(whoami)
        show_str_Red "${DATE} ${USER} $0 [ERROR] $@" >>/root/$log_file
}

# function CHECK_STATUS(){
#     if [ $? == 0 ];then
#         tput rc && tput ed
#         printf "\033[1;36m%-7s\033[0m\n" 'SUCCESS'
#     else
#         tput rc && tput ed
#         printf "\033[1;31m%-7s\033[0m\n" 'FAILED'
#     fi
# }

check_redis() {
        if [ -f "/etc/redis.conf" ] || [ -d "/usr/local/redis" ]; then
                # echo -e "\033[31;1m redis directory already exists！ \033[0m"
                show_str_Red "--------------------------------------------"
                show_str_Red "|                  警告！！！              |"
                show_str_Red "|    redis directory already exists！      |"
                show_str_Red "--------------------------------------------"
                log_error "redis directory already exists"
                exit 0
        elif [ $(ps -ef | grep redis | grep -v grep | wc -l) -ne '0' ]; then
                # echo -e "\033[31;1m redis has running already exists! please check! \033[0m"
                show_str_Red "-------------------------------------------------------------"
                show_str_Red "|                        警告！！！                         |"
                show_str_Red "|    redis has running already exists! please check!        |"
                show_str_Red "-------------------------------------------------------------"
                log_error "redis has running already exists! please check!"
                exit 0
        else
                # show_str_Green "检测当前服务器未安装redis"
                show_str_Green "-------------------------------------------"
                show_str_Green "|                提醒！！！                |"
                show_str_Green "|       检测当前服务器未安装Redis          |"
                show_str_Green "-------------------------------------------"
                log_correct "检测当前服务器未安装Redis"
        fi
}

redis_status() {
        status=$(systemctl status redis | grep running | wc -l)
        if [ $status -eq '1' ]; then
                redis_info
        else
                show_str_Red "----------------------------------"
                show_str_Red "|            警告！！！            |"
                show_str_Red "|    Redis 启动失败，请联系管理员！  |"
                show_str_Red "----------------------------------"
                exit 0
        fi
}

redis_info() {
        show_str_Green "========================================"
        show_str_Green "             Redis安装完成!"
        show_str_Green "========================================"
        show_str_Purple "systemctl start redis #启动服务"
        show_str_Purple "rsystemctl stop redis #停止服务"
        show_str_Purple "systemctl restart redis #重启服务"
        show_str_Purple "systemctl status redis #查看服务状态"
        show_str_Purple "systemctl enable redis #设置开机自启动"
        show_str_Purple "Redis密码：$redis_pass"
}

install_redis() {
        read -p "please input redis installation method(yum or make):" method
        case $method in
        yum | Yum)
                show_str_Yellow "========================================"
                show_str_Yellow "            epel仓库安装中。。。"
                show_str_Yellow "========================================"
                yum install epel-release -y >>/root/$log_file 2>&1
                show_str_Green "========================================"
                show_str_Green "            epel仓库安装完成！！！"
                show_str_Green "========================================"
                show_str_Yellow "========================================"
                show_str_Yellow "            安装redis中。。。"
                show_str_Yellow "========================================"
                yum install redis -y >>/root/$log_file 2>&1
                sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis.conf
                sed -i 's/bind 127.0.0.1/bind '$ip'/g' /etc/redis.conf
                sed -i 's/# requirepass foobared/requirepass '$redis_pass'/g' /etc/redis.conf
                systemctl start redis >>/root/$log_file 2>&1
                systemctl enable redis >>/root/$log_file 2>&1
                redis_status
                ;;
        make | Make)
                show_str_Yellow "========================================"
                show_str_Yellow "            安装相关依赖。。。"
                show_str_Yellow "========================================"
                yum -y install gcc gcc-c++ kernel-devel libstdc++-devel >>/root/$log_file 2>&1
                show_str_Yellow "========================================"
                show_str_Yellow "            下载源码并解压。。。"
                show_str_Yellow "========================================"
                if [ ! -f '/root/redis-7.0.5.tar.gz' ]; then
                        wget http://download.redis.io/releases/redis-7.0.5.tar.gz >>/root/$log_file 2>&1
                fi
                tar xf /root/redis-7.0.5.tar.gz
                cd /root/redis-7.0.5
                make >>/root/$log_file 2>&1
                make PREFIX=/usr/local/redis install >>/root/$log_file 2>&1
                show_str_Green "========================================"
                show_str_Green "            编译安装完成！！！"
                show_str_Green "========================================"
                mkdir -p /usr/local/redis/etc/
                cp /root/redis-7.0.5/redis.conf /usr/local/redis/etc/
                cd /usr/local/redis/bin/
                cp redis-benchmark redis-cli redis-server /usr/bin/
                cat <<EOF >/usr/lib/systemd/system/redis.service
[Unit]
Description=Redis
After=network.target

[Service]
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis.conf --daemonize no
ExecStop=/usr/local/bin/redis-cli shutdown

[Install]
WantedBy=multi-user.target
EOF
                chmod 745 /lib/systemd/system/redis.service
                systemctl daemon-reload
                sed -i 's/protected-mode yes/protected-mode no/g' /usr/local/redis/etc/redis.conf
                sed -i 's/bind 127.0.0.1/bind '$ip'/g' /usr/local/redis/etc/redis.conf
                sed -i 's/# requirepass foobared/requirepass '$redis_pass'/g' /usr/local/redis/etc/redis.conf
                systemctl start redis >>/root/$log_file 2>&1
                systemctl enable redis >>/root/$log_file 2>&1
                redis_status
                ;;
        *)
                show_str_Red "----------------------------------"
                show_str_Red "|            警告！！！            |"
                show_str_Red "|    请 输 入 正 确 的 选 项       |"
                show_str_Red "----------------------------------"
                install_redis
                ;;
        esac
}

uninstall_redis() {
        uninstall_date=$(date +"%Y-%m-%d-%H%M%S")
        trash=/tmp/trash/$uninstall_date
        systemctl stop redis.service &>/dev/null
        systemctl disable redis.service &>/dev/null
        if [ -f '/lib/systemd/system/redis.service' ]; then
                mv /lib/systemd/system/redis.service $trash
        fi
        systemctl daemon-reload
        yum -y remove redis >>/root/$log_file 2>&1
        if [ -f "/etc/redis.conf" ] || [ -d "/usr/local/redis" ]; then
                mkdir -p $trash
                mv /etc/redis.conf $trash &>/dev/null
                mv /usr/local/redis/ $trash &>/dev/null
        fi
        if [ -f "/root/redis-7.0.5" ]; then
                mv /root/redis-7.0.5/ $trash
        fi
        show_str_Purple "========================================"
        show_str_Purple "            卸载完成！！！"
        show_str_Purple "     已将相关目录文件移除到：$trash"
        show_str_Purple "========================================"

}

function printinput() {
        echo "========================================"
        cat <<EOF
|-------------系-统-信-息--------------
|  时间            :$DATE                                        
|  主机名称        :$HOSTNAME
|  当前用户        :$USER                                        
|  内核版本        :$KERNEL
|  系统版本        :$SYSTEM  
----------------------------------------
----------------------------------------
|****请选择你要操作的项目:[0-3]****|
----------------------------------------
(1) 检查当前环境
(2) 安装Redis
(3) 卸载Redis
(0) 退出
EOF

        read -p "请选择[0-3]: " input
        case $input in
        1)
                check_redis
                printinput
                ;;
        2)
                install_redis
                printinput
                ;;
        3)
                uninstall_redis
                printinput
                ;;
        0)
                # log_correct "exit"
                clear
                exit 0
                ;;
        *)
                show_str_Red "----------------------------------"
                show_str_Red "|            警告！！！            |"
                show_str_Red "|    请 输 入 正 确 的 选 项       |"
                show_str_Red "----------------------------------"
                for i in $(seq -w 3 -1 1); do
                        echo -ne "\b\b$i"
                        sleep 1
                done
                printinput
                ;;
        esac
}
printinput
