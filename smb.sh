#!/bin/bash

##############################################################################
#   脚本名称: install.sh 
#   版本:1.00  
#   语言:bash shell  
#   日期:2018-05-15 
#   作者:运维组 
#   QQ:246579762
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
INSTALL_DIR=$3
DATA_PATH=$4

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

# 修改系统环境变量
set_smb_cnf() {

    mkdir -p ${INSTALL_DIR}/samba/logs ${DATA_PATH}
    cat >> ${INSTALL_DIR}/samba/etc/smb.conf << EOF
[global]
    workgroup = MYGROUP
    netbios name = Samba_Server
    server string = Linux Samba Server
    security = user
    log file = ${INSTALL_DIR}/samba/logs/log.%m
    max log size = 10240
    #display charset = CP936
    #unix charset = CP936
    #dos charset = CP936
    #client code page= CP936

[data]
    path=${DATA_PATH}
    writeable = yes
    browseable = yes
    create mode = 0775
EOF
}

install_smb() {

    echo "开始安装依赖包..."
    # for p in attr bind-utils docbook-style-xsl gcc gdb krb5-workstation \
 #       libsemanage-python libxslt perl perl-ExtUtils-MakeMaker \
 #       perl-Parse-Yapp perl-Test-Base pkgconfig policycoreutils-python \
 #       python-crypto gnutls-devel libattr-devel keyutils-libs-devel \
 #       libacl-devel libaio-devel libblkid-devel libxml2-devel openldap-devel \
 #       pam-devel popt-devel python-devel readline-devel zlib-devel systemd-devel; do
        
    for p in gcc gcc-c++ gnutls-devel python python-devel python-lib* libacl-devel openldap-devel pam pam-deve; do
        myum $p
    done

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "开始安装Samba，大概需要5-10分钟，请耐性等待..."
    dir_exists ${INSTALL_DIR}/samba

    cd ${PACKAGE_DIR}
    tar xf samba-4.7.0.tar.gz
    check_ok
    cd samba-4.7.0
    ./configure --prefix=${INSTALL_DIR}/samba
    check_ok
    make && make install
    check_ok

    # 添加动态链接库，并加载动态链接库
    echo "/usr/local/samba/lib" >> /etc/ld.so.conf
    ldconfig 

    echo "开始添加配置文件..."
    set_smb_cnf
}

#--------------------------------- 部署选择 ---------------------------------#
install_smb


# 接下来、创建用户,注：这里需要系统上已存在的用户，不然会报错

# useradd samba

# /usr/local/samba/bin/pdbedit -a -u samba
# new password:    #输入密码
# retype new password:  #再次输入
# Unix username:        samba
# NT username:          
# Account Flags:        [U          ]
# User SID:             S-1-5-21-2155642128-2869549891-154057661-1000
# Primary Group SID:    S-1-5-21-2155642128-2869549891-154057661-513
# Full Name:            
# Home Directory:       \\nnn-10\samba
# HomeDir Drive:        
# Logon Script:         
# Profile Path:         \\nnn-10\samba\profile
# Domain:               NNN-10
# Account desc:         
# Workstations:         
# Munged dial:          
# Logon time:           0
# Logoff time:          Wed, 06 Feb 2036 23:06:39 CST
# Kickoff time:         Wed, 06 Feb 2036 23:06:39 CST
# Password last set:    Fri, 26 May 2017 20:43:59 CST
# Password can change:  Fri, 26 May 2017 20:43:59 CST
# Password must change: never
# Last bad password   : 0
# Bad password count  : 0
# Logon hours         : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF


# 查看用户是否创建成功

# /usr/local/samba/bin/pdbedit -L
# samba:500:

# 启动samba服务器
# /usr/local/samba/sbin/smbd