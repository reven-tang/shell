#!/bin/bash

##############################################################################
#   脚本名称: install.sh 
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

IS_DOWNLOAD=$2

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
# 部署软件
deployment() {

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    # 给脚本赋予执行权限
    chmod +x ${PACKAGE_DIR}/*.sh

    echo -e "${green}开始部署软件...${none}"
    . ${PACKAGE_DIR}/${PACKAGE_NAME}.sh
    check_ok
}

uninstall() {

    ACTIVE=2
    read -p "请输入要卸载的软件名称: " PACKAGE_NAME
    read -p "请按回车确认卸载：" var
    . ${PACKAGES_DIR}/${PACKAGE_NAME}/${PACKAGE_NAME}.sh
}

rollback() {

    ACTIVE=3
    read -p "请输入要回滚的软件名称: " PACKAGE_NAME
    read -p "请按回车确认卸载：" var
    . ${PACKAGES_DIR}/${PACKAGE_NAME}/${PACKAGE_NAME}.sh
}

#--------------------------------- 部署选择 ---------------------------------#
case "$1" in
    jdk|jboss|nginx|tomcat|mysql|mariadb|rabbitmq|zookeeper|vsftpd|smb|elk|redis|cachecloud)
        deployment
        . ${ENV_DIR}
        ;;
    uninstall)
        uninstall
        . ${ENV_DIR}
        ;;
    rollback)
        rollback
        . ${ENV_DIR}
        ;;
    *)
        echo -e $"${yellow}Usage: $0 {soft_module_name | uninstall | rollback}${none}"
        echo -e $"${yellow}Example: install.sh <jdk|jboss|nginx|tomcat|mysql|mariadb|rabbitmq|zookeeper|vsftpd|smb|elk|redis|cachecloud> ${none}"
        exit 1
        ;;
esac

# curl -s http://192.168.124.169:86/software/install.sh | bash -s 