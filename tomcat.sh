#!/bin/bash

##############################################################################
#   脚本名称: tomcat.sh 
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
INSTALL_DIR=$3
TOMCAT_NUM=$4
HTTP_PORTS=$5
AJP_PORTS=$6
SHUTDOWN_PORTS=$7

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
# 修改网站发布目录（可选）
# WEB_PATH="/usr/local/Reven_vip002/Reven_vipDynamic/"
install_tomcat() {

    echo "开始部署tomcat..."
    cd ${INSTALL_DIR}
    tar -xf ${PACKAGE_DIR}/apache-tomcat-*.tar.gz
    mv apache-tomcat-* tomcat${i}
    check_ok 

    echo "开始修改启动脚本..."
    sed  -i '1a\CATALINA_OPTS=-Dfile.encoding=GB18030\nJAVA_OPTS="-server -Xms1024m -Xmx1024m -XX:PermSize=256m -XX:MaxPermSize=512m" \
    JAVA_HOME='`ls -d /usr/java/jdk*` ${INSTALL_DIR}/tomcat${i}/bin/catalina.sh
    check_ok

    echo "开始修改配置文件..."
    sed -i "/Server port=\"8005\" shutdown=\"SHUTDOWN\"/s/8005/${SHUTDOWN_PORT}/" ${INSTALL_DIR}/tomcat${i}/conf/server.xml
    check_ok

    sed -i "/Connector port=\"8080\" protocol=\"HTTP\/1.1\"/s/8080/${HTTP_PORT}/" ${INSTALL_DIR}/tomcat${i}/conf/server.xml
    check_ok

    sed -i "/Connector port=\"8009\" protocol=\"AJP\/1.3\"/s/8009/${AJP_PORT}/" ${INSTALL_DIR}/tomcat${i}/conf/server.xml
    check_ok

    sed -i "/connectionTimeout=\"20000\"/a\               maxThreads=\"500\"\n               disableUploadTimeout=\"true\"\n\
               enableLookups=\"false\"" ${INSTALL_DIR}/tomcat${i}/conf/server.xml
    check_ok

    # 修改网站发布目录（可选）
    # sed -i "/<\/Host>/i\        <Context path=\"\/\" docBase=\"${WEB_PATH}\" \/>" ${INSTALL_DIR}/tomcat${i}/conf/server.xml
}

# Main函数入口
main(){

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "创建安装目录"
    dir_exists ${INSTALL_DIR}
    
    # read -p "请输入tomcat实例个数：" TOMCAT_NUM 
    # read -p "请输入HTTP起始端口(原端口为8080)：" HTTP_PORTS
    # read -p "请输入AJP起始端口(原端口为8009)：" AJP_PORTS
    # read -p "请输入SHUTDOWN起始端口(原端口为8005)：" SHUTDOWN_PORTS 
    for ((i=0; i<${TOMCAT_NUM}; i++)); do
        HTTP_PORT=`expr ${HTTP_PORTS} + ${i}`
        AJP_PORT=`expr ${AJP_PORTS} + ${i}`
        SHUTDOWN_PORT=`expr ${SHUTDOWN_PORTS} + ${i}`
        install_tomcat
        sleep 1
    done    
}

#--------------------------------- 部署选择 ---------------------------------#
main
