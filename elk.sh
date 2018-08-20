#!/bin/bash

##############################################################################
#   脚本名称: elk.sh 
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
MENU_CHOOSE=$3
INSTALL_DIR=$4
ES_DIR_NAME=$5
HEAD_PORT=$6
ES_URL=$7

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

    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        # 创建介质存放目录
        mkdir -p ${PACKAGE_DIR}
        wget -P ${PACKAGE_DIR} -r -np -nd -nH -R index.html -q ${DOWNLOAD_URL}"/"
        check_ok
    fi
}

#--------------------------------- 程序模块 ---------------------------------#

#------------------------------- set env ------------------------------------#
set_limits_and_vm(){
    echo "开始修改文件数"
        cat >> /etc/security/limits.conf << EOF

*               soft    nofile          65536
*               hard    nofile          131072
elastic         soft    nofile          65536
elastic         hard    nofile          65536
elastic         soft    nproc           65536
elastic         hard    nproc           65536

# allow elastic mlockall
elastic         soft    memlock         unlimited
elastic         hard    memlock         unlimited

EOF
    #################################################
    # *               soft    nofile          65536
    # *               hard    nofile          131072
    # elastic         soft    nofile          65536
    # elastic         hard    nofile          65536
    # elastic         soft    nproc           65536
    # elastic         hard    nproc           65536
    #################################################

    echo "开始配置最大虚拟内存"
    cat >> /etc/sysctl.conf << EOF

fs.file-max=65536
vm.max_map_count=262144
EOF
    # 生效
    sysctl -p
}

#-------------------------- Install ElasticSearch ---------------------------#
# 开始安装ES
install_es() {

    echo -e "${green}创建elastic用户 ${none}"
    create_user elastic
    check_ok

    echo -e "${green}解压ES到指定目录下 ${none}"
    tar -xf ${PACKAGE_DIR}/elasticsearch-*.tar.gz -C ${INSTALL_DIR}
    mv ${INSTALL_DIR}/elasticsearch* ${INSTALL_DIR}/${ES_DIR_NAME}
    check_ok

    # 配置ES
    sed -r -i 's#-Xms2g#-Xms1g#g' ${INSTALL_DIR}/${ES_DIR_NAME}/config/jvm.options
    sed -r -i 's#-Xmx2g#-Xmx1g#g' ${INSTALL_DIR}/${ES_DIR_NAME}/config/jvm.options

    cp -a ${INSTALL_DIR}/${ES_DIR_NAME}/config/elasticsearch.yml ${INSTALL_DIR}/${ES_DIR_NAME}/config/elasticsearch.yml_bak
    cat > ${INSTALL_DIR}/${ES_DIR_NAME}/config/elasticsearch.yml.sample << EOF
cluster.name: Reven-Log-Platform
node.name: log-master-136
node.master: true
node.data: false
path.data: ${INSTALL_DIR}/${ES_DIR_NAME}/data
path.logs: ${INSTALL_DIR}/${ES_DIR_NAME}/logs
bootstrap.system_call_filter: false
network.host: 172.20.201.136
http.enabled: true
http.port: 9000
transport.tcp.port: 9100
discovery.zen.ping.unicast.hosts: ["172.20.201.136:9100","172.20.201.137:9100","172.20.201.138:9100","172.20.201.136:8100","172.20.201.137:8100","172.20.201.138:8100"]
discovery.zen.minimum_master_nodes: 2
action.destructive_requires_name: true
http.cors.enabled: true
http.cors.allow-origin: "*"
gateway.recover_after_data_nodes: 3
gateway.recover_after_time: 3m
gateway.expected_data_nodes: 5
bootstrap.memory_lock: true
indices.fielddata.cache.size: 60%
cluster.routing.allocation.disk.threshold_enabled: true
cluster.routing.allocation.disk.watermark.low: 90%
thread_pool.search.size: 150
thread_pool.search.queue_size: 1000
thread_pool.bulk.size: 30
thread_pool.bulk.queue_size: 2000
thread_pool.index.size: 30
thread_pool.index.queue_size: 1000
indices.ttl.interval: 60s

http.cors.enabled: true
http.cors.allow-origin: "*"
EOF

    # 修改目录权限
    chown -R elastic:elastic ${INSTALL_DIR}/${ES_DIR_NAME}

    echo -e "${yellow}ES安装完成,启动前请手工修改配置文件，参考样例：${INSTALL_DIR}/${ES_DIR_NAME}/config/elasticsearch.yml.sample ${none}"
}

#--------------------------- Install Head Plugin ----------------------------#
# 修改系统环境变量
set_node_env() {

    cat >> ${ENV_DIR} << EOF

NodeJS Creation time is ${ACTIVE_TIME}
export NODE_HOME=`ls -d "${INSTALL_DIR}/node"`
export PATH=\$PATH:\$NODE_HOME/bin
EOF

    sed -r -i "/^NodeJS Creation time is ${ACTIVE_TIME}/s/^/###/" ${ENV_DIR}
    # 生效环境变量
    source ${ENV_DIR}
    check_ok
}

# 修改head配置文件
head_conf(){

    # 修改服务器监听地址
    sed -i "/port: 9100/a\\\t\t\\t\t\thostname: '*'," ${INSTALL_DIR}/elasticsearch-head/Gruntfile.js
    sed -i "s/port: 9100/port: ${HEAD_PORT}/" ${INSTALL_DIR}/elasticsearch-head/Gruntfile.js

    # 修改连接地址
    sed -r -i "s#http://localhost:9200#${ES_URL}#g" ${INSTALL_DIR}/elasticsearch-head/_site/app.js
}

# 开始安装head插件
install_head() {

    echo "开始安装依赖包..."
    for p in make git npm xz openssl openssl-devel; do
        myum $p
    done

    echo "将head插件部署到${INSTALL_DIR}目录下"
    # 或者下载插件：git clone git://github.com/mobz/elasticsearch-head.git
    tar -xf ${PACKAGE_DIR}/elasticsearch*head.tar.gz -C ${INSTALL_DIR}
    check_ok

    echo "解压node到${INSTALL_DIR}目录下"
    cd ${PACKAGE_DIR}
    [ -f node-*.tar.xz ] && xz -d node-*.tar.xz
    tar -xf node-*.tar -C ${INSTALL_DIR}
    check_ok
    mv ${INSTALL_DIR}/node-* ${INSTALL_DIR}/node

    echo "开始添加NodeJS环境变量"
    set_node_env

    echo "安装head插件..."
    cd ${INSTALL_DIR}/elasticsearch-head
    # 国内的用不了nmp 用淘宝的cnmp源，或使用http://r.cnpmjs.org/
    npm install cnpm -g --registry=https://registry.npm.taobao.org
    check_ok
    sleep 2

    cnpm install -g grunt-cli
    cnpm install
    check_ok

    echo "修改head插件配置文件"
    head_conf

    # 修改ES配置文件，增加以下参数，使head可以访问ES
    echo "修改ES配置文件，添加启动HTTP配置"
    cat >> ${INSTALL_DIR}/${ES_DIR_NAME}/config/elasticsearch.yml << EOF

http.cors.enabled: true
http.cors.allow-origin: "*"
EOF

    echo "修改head目录所有权给elastic用户"
    chown -R elastic:elastic ${INSTALL_DIR}/elasticsearch-head
}

#-------------------- ------- Install SQL Plugin ----------------------------#
install_sql(){

    echo "解压SQL插件包"
    # 安装sql插件到es的plugins,注意跟ES的版本要对应起来
    ${INSTALL_DIR}/${ES_DIR_NAME}/bin/elasticsearch-plugin install \
    https://github.com/NLPchina/elasticsearch-sql/releases/download/5.5.2.0/elasticsearch-sql-5.5.2.0.zip
    check_ok
    unzip ${PACKAGE_DIR}/es-sql-site-standalone*.zip -d ${INSTALL_DIR}/${ES_DIR_NAME}/plugins/sql/

    echo "安装sql前端"
    cd ${INSTALL_DIR}/${ES_DIR_NAME}/plugins/sql/site-server
    cnpm install express --save
    check_ok

    echo "重新修改${INSTALL_DIR}目录权限"
    chown -R elastic:elastic ${INSTALL_DIR}/${ES_DIR_NAME}
}

#--------------------------------- 部署选择 ---------------------------------#

pkg_download
echo "创建安装目录"
dir_exists ${INSTALL_DIR}

case "${MENU_CHOOSE}" in
    1|ES|es)
        set_limits_and_vm
        install_es
        ;;
    2|HEAD|head)
        install_head
        ;;
    3|SQL|sql)
        install_sql
        ;;
    4|ALL|all)
        $0 ES
        $0 HEAD
        $0 SQL
        ;;
    *)
        echo $"Usage: $0 {es | head | sql | all}, Parameter "all" is to install the es, head and sql plugins."
        exit 1
        ;;
esac

####################################################################################################
# 启动ES
# su - elastic -c "${INSTALL_DIR}/${ES_DIR_NAME}/bin/elasticsearch -d"
# 启动nodejs
# source ${ENV_DIR}
# cd ${INSTALL_DIR}/elasticsearch-head/ && grunt server &
# 启动sql插件
# su - elastic -c "cd ${INSTALL_DIR}/${ES_DIR_NAME}/plugins/sql/site-server/ && node node-server.js &"
# ##################################################################################################