#!/bin/bash

##############################################################################
#   脚本名称: jboss.sh 
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
JBOSS_NUM=$4
HTTP_PORTS=$5
AJP_PORTS=$6
HTTPS_PORTS=$7
OSGI_PORTS=$8

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

#--------------------------------- 服务模块 ---------------------------------#
# 创建JBOSS启动脚本
create_jboss_service() {

    cat > /etc/init.d/jboss << EOF
#!/bin/bash

##############################################################################
#   脚本名称: jboss.sh 
#   版本:3.00  
#   语言:bash shell  
#   日期:2017-08-20 
#   作者:Reven 
#   邮箱:254674563@qq.com
##############################################################################
JBOSS_NUM=${JBOSS_NUM}

start() {
    echo -n \$"Starting Jboss: "
    for ((i=0; i<\${JBOSS_NUM}; i++)); do
        /usr/bin/nohup ${INSTALL_DIR}/jboss\${i}/bin/standalone.sh >/dev/null 2>&1 &
        sleep 1
    done  
    echo
}
Revenp() {
    echo -n \$"Revenpping Jboss: "
    ps aux | grep "Djboss.home.dir" | grep -v grep | awk '{print \$2}' | xargs kill

    pid_count=\`ps aux | grep "Djboss.home.dix" | grep -v grep | awk '{print \$2}' | wc -l\`
    while ((\$pid_count != 0)) ; do
        sleep 2
    done
    echo
}

###############################################################################
case "\$1" in
    start)
        start
        ;;
    Revenp)
        Revenp
        ;;
    restart)
        \$0 Revenp
        \$0 start
        ;;
    *)
        echo $"Usage: \$0 {start|Revenp|restart}"
        exit 1
        ;;
esac

EOF

    chmod 755 /etc/init.d/jboss
}

#--------------------------------- 程序模块 ---------------------------------#
# 开始安装
install_jboss() {

    echo "开始部署jboss..."
    cd ${INSTALL_DIR}
    unzip ${PACKAGE_DIR}/jboss-as*.zip
    mv jboss-as* jboss${i}
    check_ok

    echo "开始修改配置文件..."
    cp -a ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml_bak

    sed -i 's#<socket-binding name="management-native"#<!--socket-binding name="management-native"#g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml

    sed -i 's#{jboss.management.https.port:9443}"/>#{jboss.management.https.port:9443}"/-->#g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml

    sed -r -i '/\/interfaces/i\        <interface name = "any">\n            <any-ipv4-address/>\n        </interface>' \
    ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml
    check_ok

    sed -r -i 's/default-interface="public"/default-interface="any"/g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml
    check_ok

    sed -r -i '/socket-binding name="http"/s/port="8080"/port="'"${HTTP_PORT}"'"/g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml
    check_ok

    sed -r -i '/socket-binding name="ajp"/s/port="8009"/port="'"${AJP_PORT}"'"/g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml
    check_ok

    sed -r -i '/socket-binding name="https"/s/port="8443"/port="'"${HTTPS_PORT}"'"/g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml
    check_ok

    sed -r -i '/socket-binding name="osgi-http"/s/port="8090"/port="'"${OSGI_PORT}"'"/g' ${INSTALL_DIR}/jboss${i}/standalone/configuration/standalone.xml
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

    echo "传递参数：${INSTALL_DIR}"
    dir_exists ${INSTALL_DIR}

    # read -p "请输入Jboss实例个数：" JBOSS_NUM 
    # read -p "请输入HTTP起始端口(原端口为8080)：" HTTP_PORTS
    # read -p "请输入AJP起始端口(原端口为8009)：" AJP_PORTS
    # read -p "请输入HTTPS起始端口(原端口为8443)：" HTTPS_PORTS
    # read -p "请输入OSGI-HTTP起始端口(原端口为8090)：" OSGI_PORTS
    for ((i=0; i<${JBOSS_NUM}; i++)); do
        HTTP_PORT=`expr ${HTTP_PORTS} + ${i}`
        AJP_PORT=`expr ${AJP_PORTS} + ${i}`
        HTTPS_PORT=`expr ${HTTPS_PORTS} + ${i}`
        OSGI_PORT=`expr ${OSGI_PORTS} + ${i}`
        install_jboss
        check_ok
        sleep 1
    done  

    create_jboss_service
}

#--------------------------------- 部署选择 ---------------------------------#
main
