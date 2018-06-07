#!/bin/bash

##############################################################################
#   脚本名称: rabbitmq.sh 
#   版本:3.00  
#   语言:bash shell  
#   日期:2017-09-30 
#   作者:Reven 
#   QQ:254674563
##############################################################################

# 颜色定义
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
none='\e[0m'

# 定义脚本环境变量
PACKAGE_NAME=${1}
PACKAGES_DIR="/usr/local/script"
PACKAGE_DIR="/usr/local/script/${1}"
SHELL_DIR="/usr/local/script/${1}"
DOWNLOAD_URL="http://192.168.124.169:86/software/${1}"
ENV_DIR="/etc/profile"
ACTIVE=1    # 1：部署  2：卸载  3：回滚 
ACTIVE_TIME=`date '+%Y-%m-%d'`

MENU_CHOOSE=$2
IS_DOWNLOAD=$3
INSTALL_DIR=$4
MQ_ADMIN_USER=$5
MQ_ADMIN_PASS=$6
MQ_OPER_USER=$7
MQ_OPER_PASS=$8

#--------------------------------- 基础模块 ---------------------------------#
# 检查命令是否正确运行
check_ok() {

    if [ $? != 0 ] ; then
        echo -e "${red}[*] Error! Error! Error! Please check the error info. ${none}"
        exit 1
    fi
}

# 如果包已经安装，则提示并跳过安装.
myum() {

    if ! rpm -qa | grep -q "^$1" ; then
        yum install -y $1
        check_ok
    else
        echo $1 already installed
    fi
}

# 添加用户
create_user() {

    if ! grep "^$1:" /etc/passwd ; then
        useradd $1
        echo "$1" | passwd "$1" --stdin &>/dev/null
        check_ok
    else
        echo $1 already exist!
    fi
}

# 确保目录存在
dir_exists() {

    [ ! -d "$1" ] && mkdir -p $1
}

pkg_download() {

    # 创建介质存放目录
    mkdir -p ${PACKAGE_DIR}
    wget -P ${PACKAGE_DIR} -r -np -nd -nH -R index.html -q ${DOWNLOAD_URL}"/"
}

#--------------------------------- 程序模块 ---------------------------------#
# 开始安装Erlang
install_erlang() {

    echo "开始执行编译安装otp"
    sleep 2
    cd ${PACKAGE_DIR}

    if [ ${MENU_CHOOSE} = 1 ]; then
        tar -xf ${PACKAGE_DIR}/otp_src_R16B03.tar.gz
        check_ok
        cd ${PACKAGE_DIR}/otp_src_R16B03
    else
        tar -xf ${PACKAGE_DIR}/otp_src_18.0.tar.gz
        check_ok
        cd ${PACKAGE_DIR}/otp_src_18.0
    fi

    ./configure
    check_ok
    make && make install
    check_ok
}

# 开始安装xmlto
install_xmlto() {

    echo "开始执行编译安装xmlto"
    sleep 2
    cd ${PACKAGE_DIR}
    tar -xf ${PACKAGE_DIR}/xmlto-0.0.28.tar.gz
    check_ok

    cd ${PACKAGE_DIR}/xmlto-0.0.28
    ./configure
    check_ok
    make && make install
    check_ok
}

# 开始安装RabbitMQ
install_rabbitmq_v342() {

    echo "开始执行编译安装RabbitMQ"
    echo "创建安装目录"
    dir_exists ${INSTALL_DIR}

    sleep 2
    cd ${PACKAGE_DIR}
    [ -f rabbitmq-server-[0-9]*.tar.xz ] && xz -d rabbitmq-server-[0-9]*.tar.xz
    tar -xf ${PACKAGE_DIR}/rabbitmq-server-[0-9]*.tar*
    check_ok

    cd ${PACKAGE_DIR}/rabbitmq-server*[0-9]
    make TARGET_DIR=${INSTALL_DIR}/rabbitmq SBIN_DIR=${INSTALL_DIR}/rabbitmq/sbin \
    MAN_DIR=${INSTALL_DIR}/rabbitmq/man DOC_INSTALL_DIR=${INSTALL_DIR}/rabbitmq/doc install
    check_ok

    # 添加rabbit用户,创建所需目录
    useradd rabbit
    mkdir -p /etc/rabbitmq
    mkdir -p /var/lib/rabbitmq
    mkdir -p /var/log/rabbitmq 
    chown -R rabbit.rabbit /etc/rabbitmq
    chown -R rabbit.rabbit /var/lib/rabbitmq
    chown -R rabbit.rabbit /var/log/rabbitmq
    chown -R rabbit.rabbit ${INSTALL_DIR}/rabbitmq

    # 后台启动rabbitmq
    # cd ${INSTALL_DIR}/rabbitmq/sbin && nohup ./rabbitmq-server >/dev/null 2>&1 &
    su - rabbit -c "${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-server -detached"
    sleep 2
    su - rabbit -c "${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-plugins list"

    # 启动web插件
    su - rabbit -c "${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-plugins enable rabbitmq_management"

}

install_rabbitmq_v365() {

    echo "开始安装RabbitMQ"
    echo "开始执行编译安装RabbitMQ"
    echo "创建安装目录"
    dir_exists ${INSTALL_DIR}

    sleep 2
    cd ${PACKAGE_DIR}
    [ -f rabbitmq-server-generic-unix-[0-9]*.tar.xz ] && xz -d rabbitmq-server-generic-unix-[0-9]*.tar.xz
    tar -xf ${PACKAGE_DIR}/rabbitmq-server-generic-unix-[0-9]*.tar -C ${INSTALL_DIR}
    check_ok

    cd ${INSTALL_DIR}
    mv rabbitmq_server-[0-9]* rabbitmq
    echo "RABBITMQ_MNESIA_BASE=${INSTALL_DIR}/rabbitmq/data" >> ${INSTALL_DIR}/rabbitmq/etc/rabbitmq/rabbitmq-env.conf
    echo "RABBITMQ_LOG_BASE=${INSTALL_DIR}/rabbitmq/data/log" >> ${INSTALL_DIR}/rabbitmq/etc/rabbitmq/rabbitmq-env.conf

    cp -a ${PACKAGE_DIR}/rabbitmq.config ${INSTALL_DIR}/rabbitmq/etc/rabbitmq/

    mkdir -p ${INSTALL_DIR}/rabbitmq/data/log

    useradd rabbit
    chown -R rabbit:rabbit ${INSTALL_DIR}/rabbitmq
    ln -s ${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-server /usr/bin/rabbitmq-server
    ln -s ${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-env /usr/bin/rabbitmq-env
    ln -s ${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-plugins /usr/bin/rabbitmq-plugins
    ln -s ${INSTALL_DIR}/rabbitmq/sbin/rabbitmqctl /usr/bin/rabbitmqctl

    # 后台启动rabbitmq
    # su - rabbit -c "cd ${INSTALL_DIR}/rabbitmq/sbin && nohup ./rabbitmq-server >/dev/null 2>&1 &"
    su - rabbit -c "${INSTALL_DIR}/rabbitmq/sbin/rabbitmq-server -detached"
    sleep 2

    # 启动web插件
    su - rabbit -c "rabbitmq-plugins enable rabbitmq_management"
}

# 修改系统环境变量
set_rabbitmq_env() {

    cat >> ${ENV_DIR} << EOF

RabbitMQ Creation time is ${ACTIVE_TIME}
export ERL_HOME=/usr/local/lib/erlang
export RABBITMQ_HOME=${INSTALL_DIR}/rabbitmq/sbin
export PATH=\$RABBITMQ_HOME:\$ERL_HOME/bin:\$PATH
EOF
    sed -r -i "/^RabbitMQ Creation time is ${ACTIVE_TIME}/s/^/###/" ${ENV_DIR}
    # 生效环境变量
    source ${ENV_DIR}
    check_ok
}

# 添加安全认证
rabbitmq_auth() {

    su - rabbit -c "rabbitmqctl add_user ${MQ_ADMIN_USER} ${MQ_ADMIN_PASS}"
    check_ok
    su - rabbit -c "rabbitmqctl set_user_tags ${MQ_ADMIN_USER} administrator"
    check_ok
    su - rabbit -c "rabbitmqctl add_user ${MQ_OPER_USER} ${MQ_OPER_PASS}"
    check_ok
    su - rabbit -c "rabbitmqctl set_user_tags ${MQ_OPER_USER} management"
    check_ok
    su - rabbit -c "rabbitmqctl delete_user guest"
    check_ok
    su - rabbit -c "rabbitmqctl set_permissions -p / ${MQ_ADMIN_USER} \".*\" \".*\" \".*\""
    check_ok
    su - rabbit -c "rabbitmqctl set_permissions -p / ${MQ_OPER_USER} \".*\" \".*\" \".*\""
    check_ok
}

# Main函数入口
main(){

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    # 安装依赖包
    for p in gcc make gcc-c++ xmlto zip unzip ncurses-devel openssl-devel nc python-simplejson \
    git-core docbook-style unixODBC-devel mesa* freeglut* xz ; do
        myum $p
    done


    case "${MENU_CHOOSE}" in
        1|3.4.2)
            install_erlang
            install_xmlto
            install_rabbitmq_v342
            set_rabbitmq_env
            rabbitmq_auth
            break
            ;;

        2|3.6.5)
            install_erlang
            install_rabbitmq_v365
            set_rabbitmq_env
            rabbitmq_auth
            break
            ;;
        *)
            echo "only 1(3.4.2) or 2(3.6.5)"
            exit 1
            ;;
    esac
}

#--------------------------------- 部署选择 ---------------------------------#
main