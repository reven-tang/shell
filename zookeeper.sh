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
ZK_PORT=$4

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
# 开始安装
install_zookeeper() {

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "创建安装目录"
    dir_exists ${INSTALL_DIR}

    cd ${PACKAGE_DIR}
    tar -zxvf ${PACKAGE_DIR}/zookeeper-[0-9]*.tar.gz -C ${INSTALL_DIR}
    check_ok
    mv ${INSTALL_DIR}/zookeeper-[0-9]* ${INSTALL_DIR}/zookeeper
    cd ${INSTALL_DIR}/zookeeper/conf
    mkdir -p ${INSTALL_DIR}/zookeeper/data
    cp -a zoo_sample.cfg zoo.cfg

    echo "开始修改配置文件"
    sed -i '/^dataDir=/s/^/#/' zoo.cfg
    sed -i '/^#dataDir=/i\dataDir='"${INSTALL_DIR}/zookeeper/data" zoo.cfg
    sed -i 's#2181#'"${ZK_PORT}"'#g' zoo.cfg

    #############################################
    # 参考配置文件
    # tickTime=2000
    # initLimit=10
    # syncLimit=5
    # dataDir=/opt/zookeeper-3.4.9/data
    # clientPort=2181
    # ###########################################
}

# 修改系统环境变量
set_env() {

    cat >> ${ENV_DIR} << EOF

####zookeeper...
export zookeeper_HOME=`ls -d ${INSTALL_DIR}/zookeeper`
export PATH=\$PATH:\$zookeeper_HOME/bin:\$zookeeper_HOME/conf
EOF
    # 生效环境变量
    source ${ENV_DIR}
    check_ok
}

# 启动zookeeper
zookeeper_start() {

    # 启动zookeeper
    cd ${INSTALL_DIR}/zookeeper/bin
    ./zkServer.sh start
}

# Main函数入口
main(){

    install_zookeeper
    set_env
    # zookeeper_start
}


#--------------------------------- 部署选择 ---------------------------------#
main