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
MYSQL_IP=$4
MYSQL_PORT=$5
CC_PWD=$6
CC_WEB_PORT=$7

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

#------------------------------ Cachecloud模块 -------------------------------#
# 定义部署Maven函数
install_maven() {
    echo -e "${green}开始解压部署Maven服务... ${none}"
    cd ${PACKAGE_DIR}
    tar -zxvf ${PACKAGE_DIR}/apache-maven-[0-9]*.tar.gz -C ${INSTALL_DIR}
    # 修改系统环境变量
    cat >> ${ENV_DIR} << EOF

####Maven...
export MAVEN_HOME=`ls -d "${INSTALL_DIR}"/apache-maven*`
export PATH=\$MAVEN_HOME/bin:\${PATH}
EOF
        # 生效环境变量
        source ${ENV_DIR}
        check_ok

    echo -e "${green}maven部署验证结果: ${none}"
    mvn -v
}

# 定义部署CacheCloud函数
install_cachecloud() {
    echo -e "${green}开始解压部署CacheCloud服务... ${none}" 
    cd ${PACKAGE_DIR}
    mkdir ${INSTALL_DIR}/data
    unzip ${PACKAGE_DIR}/cachecloud-develop.zip -d ${INSTALL_DIR}/data

    # 在Mysql中创建cachecloud库并对cachecloud用户进行授权
    # read -p "请在Mysql数据库中进行建库(create database cachecloud;)并对cachecloud用户赋予所有权,完成后按任意键继续：" var
    # create database cachecloud;
    # grant all on cachecloud.* to cachecloud@"${CC_IP}" identified by "${CC_PWD}";
    echo "开始在Mysql数据库中创建cachecloud相关数据表..."
    mysql -h ${MYSQL_IP} -ucachecloud -p${CC_PWD} -S /tmp/mysql${MYSQL_PORT}.sock << EOF
use cachecloud;
source ${INSTALL_DIR}/data/cachecloud-develop/script/cachecloud.sql;
EOF

    ########################################################
    # 在Mysql中创建cachecloud库并对cachecloud用户进行授权
    # mysql -uroot -pxxxxxxxxxx -S /tmp/mysql3306.sock
    # create database cachecloud;
    # grant all on cachecloud.* to cachecloud@'172.16.16.103' identified by 'xxxxxxxxxx';
    # flush privileges;
    # 导入初始数据
    # use cachecloud;
    # source ${INSTALL_DIR}/data/cachecloud-develop/script/cachecloud.sql;
    # exit
    #######################################################
    
    echo "开始修改cachecloud配置文件..."

    # 编辑配置文件online.properties和local.properties
    # 修改online.properties文件
    sed -i "s/127.0.0.1/${MYSQL_IP}/" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties
    sed -i "s/cache-cloud/cachecloud/" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties
    sed -i "s/password = /password = ${CC_PWD}/" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties
    sed -r -i '/log_base/s/^/#/' ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties
    sed -r -i "/log_base/a\log_base=${INSTALL_DIR}/data/cachecloud-web/logs" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties
    sed -i 's/\r//g' ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties

    # 修改local.properties文件
    sed -i "s/127.0.0.1/${MYSQL_IP}/" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/local.properties
    sed -i "s/cache-cloud/cachecloud/" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/local.properties
    sed -i "s/password = /password = ${CC_PWD}/" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/local.properties
    sed -r -i '/log_base/s/^/#/' ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/local.properties
    sed -r -i "/log_base/a\log_base=${INSTALL_DIR}/data/cachecloud-web/logs" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/local.properties
    sed -i 's/\r//g' ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/local.properties

    # 修改cachecloud-web端口号
    # read -p "请输入Cachecloud的WEB访问端口(原端口为8585)：" CC_WEB_PORT
    sed "s/8585/${CC_WEB_PORT}/g" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/swap/online.properties

    # 修改cachecloud-web.conf文件
    sed -i "s#/data#${INSTALL_DIR}/data#g" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/resources/cachecloud-web.conf
    sed -i "s#/opt/cachecloud-web#${INSTALL_DIR}/data/cachecloud-web#g" ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/resources/cachecloud-web.conf

    # 在cachecloud根目录下运行: mvn clean compile install -Ponline
    cd ${INSTALL_DIR}/data/cachecloud-develop
    echo -e "${green}开始项目打包发布(如有修改从新打包) ${none}"
    mvn clean compile install -Ponline
    check_ok

    # 创建${INSTALL_DIR}/data/cachecloud-web目录，并拷贝相关文件
    mkdir -p ${INSTALL_DIR}/data/cachecloud-web
    cp ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/target/cachecloud-open-web-1.0-SNAPSHOT.war ${INSTALL_DIR}/data/cachecloud-web/
    cp ${INSTALL_DIR}/data/cachecloud-develop/cachecloud-open-web/src/main/resources/cachecloud-web.conf ${INSTALL_DIR}/data/cachecloud-web/
    ln -s ${INSTALL_DIR}/data/cachecloud-web/cachecloud-open-web-1.0-SNAPSHOT.war /etc/init.d/cachecloudweb 

    # 启动cachecloud-web并通过http://IP:8585访问，用户名和密码admin
    /etc/init.d/cachecloudweb start
    # # 
    # #+++++++++++++++++++++以下是需要在cachecloud管理的机器上进行操作+++++++++++++++++++++++++++#
    # # 在服务器上创建cachecloud SSH连接账号，和系统配置管理页面里的用户名和密码保持一致即可
    # # (可登陆cachecloud界面http://IP:8585进行查看系统配置管理中的机器ssh用户名和密码)
    # create_user cachecloud

    # # 创建软连接(为caclecloud部署redis单实例和集群做准备)
    # ln -s ${INSTALL_DIR}/redisdb /opt/cachecloud
    # mkdir /opt/cachecloud/{data,conf,logs} # 创建的目录视情况而定，如果有则只需要授权即可。
    # chown -R cachecloud:cachecloud /opt/cachecloud
}

# 集群主函数入口
main(){

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "创建安装目录"
    dir_exists ${INSTALL_DIR}

    install_maven
    install_cachecloud
}

#--------------------------------- 部署选择 ---------------------------------#
main