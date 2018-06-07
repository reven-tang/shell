#!/bin/bash

##############################################################################
#   脚本名称: mysql.sh 
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
MYSQL_PORT=$4
ROOT_PWD=$5
BUFFER_POOL_SIZE=$6

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
#--------------------------------- 修改配置文件 ---------------------------------#
mod_mysql_myconf() {

    cd ${INSTALL_DIR}/mysql${MYSQL_PORT}
    cp -a support-files/my-default.cnf my.cnf
    cat >> ${INSTALL_DIR}/mysql${MYSQL_PORT}/my.cnf << EOF

############### 2017-08-23 ####################
# 软件的安装目录
basedir = ${INSTALL_DIR}/mysql${MYSQL_PORT}
# 数据具体的存放位置
datadir = ${INSTALL_DIR}/mysql${MYSQL_PORT}/data
# 数据库端口
port = ${MYSQL_PORT}
# mysql服务器ID,主从需要分别配置
server_id = 70
# socket的位置，通信使用
socket = /tmp/mysql${MYSQL_PORT}.sock

#如果做主从请开启以下配置
log_bin=${INSTALL_DIR}/mysql${MYSQL_PORT}/logs/mysql-bin
relay_log=${INSTALL_DIR}/mysql${MYSQL_PORT}/logs/mysql-relay-bin
log_bin_trust_function_creators=1
log-slave-update
skip-external-locking

character_set_server = utf8
character_set_client=utf8
max_connect_errors = 20
max_connections = 2050
max_user_connections = 2050

max_heap_table_size = 64M
max_binlog_size = 500M
thread_stack = 256K
interactive_timeout = 7200
wait_timeout = 100
sort_buffer_size = 2M
read_buffer_size = 1M
read_rnd_buffer_size = 1M
join_buffer_size = 1M
net_buffer_length = 16K
thread_cache_size = 100

ft_min_word_len = 4
#transaction_isolation = READ-COMMITTED
tmp_table_size = 26214400
table_open_cache = 1000
skip_name_resolve

binlog_cache_size = 16M

innodb_additional_mem_pool_size = 2M
innodb_buffer_pool_size = ${BUFFER_POOL_SIZE}G
innodb_data_file_path = ibdata1:200M:autoextend
innodb_file_per_table
innodb_file_io_threads = 4
innodb_flush_log_at_trx_commit = 0
innodb_log_buffer_size = 8M

innodb_log_file_size = 500M
innodb_log_files_in_group = 2
innodb_max_dirty_pages_pct = 75
innodb_flush_method = O_DIRECT
innodb_lock_wait_timeout = 500
innodb_doublewrite = 1

innodb_rollback_on_timeout = OFF
innodb_autoinc_lock_mode = 1
innodb_read_io_threads = 4
innodb_write_io_threads = 4
innodb_io_capacity = 2000
innodb_purge_threads = 1
query_cache_type = 1
concurrent_insert = 1
query_cache_limit = 1048576
query_cache_min_res_unit = 1K

innodb_stats_on_metadata = OFF
innodb_file_format = Barracuda
innodb_read_ahead = 0
innodb_thread_concurrency = 0
innodb_sync_spin_loops = 100
innodb_spin_wait_delay = 30
innodb_stats_sample_pages = 8

EOF
}
#--------------------------------- 程序模块 ---------------------------------#
# 开始安装
install_mysql() {
    yum -y install autoconf
    echo "创建mysql用户"
    groupadd mysql
    useradd -r -g mysql mysql

    echo "开始安装mysql..."
    tar -zxf ${PACKAGE_DIR}/mysql*.tar.gz -C ${INSTALL_DIR}
    mv ${INSTALL_DIR}/mysql* ${INSTALL_DIR}/mysql${MYSQL_PORT}
    check_ok
    # 修改目录权限
    chown -R mysql:mysql ${INSTALL_DIR}/mysql${MYSQL_PORT}
}

# 初始化mysql
init_mysql() {
    cd ${INSTALL_DIR}/mysql${MYSQL_PORT}
    mkdir logs
    chown -R mysql:mysql logs
    echo "开始初始化Mysql"
    ./scripts/mysql_install_db --user=mysql --datadir=${INSTALL_DIR}/mysql${MYSQL_PORT}/data --defaults-file=${INSTALL_DIR}/mysql${MYSQL_PORT}/my.cnf
    check_ok
}

# 创建mysql启动脚本
create_mysql_service() {
    echo "创建启动脚本到/etc/init.d/目录下"
    cd ${INSTALL_DIR}/mysql${MYSQL_PORT}
    sed -r -i 's#^basedir=#&'"${INSTALL_DIR}"'/mysql'"${MYSQL_PORT}"'#g;s#^datadir=#&'"${INSTALL_DIR}"'/mysql'"${MYSQL_PORT}"'/data#g' support-files/mysql.server
    cp -a support-files/mysql.server /etc/init.d/mysql${MYSQL_PORT}
    chmod 755 /etc/init.d/mysql${MYSQL_PORT}
    chkconfig mysql${MYSQL_PORT} on
    # 删除系统自带的配置文件，防止启动mysql时报错
    rm -rf /etc/my.cnf

    # 将mysql客户端命令添加到用户默认路径下
    ln -s ${INSTALL_DIR}/mysql${MYSQL_PORT}/bin/mysql /usr/local/bin/mysql
    ln -s ${INSTALL_DIR}/mysql${MYSQL_PORT}/bin/mysqladmin /usr/local/bin/mysqladmin

}

# 修改系统环境变量
set_mysql_env() {
    cat >> ${ENV_DIR} << EOF
    
Mysql Creation time is ${ACTIVE_TIME}
export PATH=\$PATH:${INSTALL_DIR}/mysql${MYSQL_PORT}/bin
EOF
    sed -r -i "/^Mysql Creation time is ${ACTIVE_TIME}/s/^/###/" ${ENV_DIR}
    # 生效环境变量
    echo "生效环境变量"
    sleep 2
    source ${ENV_DIR}
    check_ok
}

# Main函数入口
main(){

    echo -e "${yellow}创建安装目录：${none}"
    dir_exists ${INSTALL_DIR}

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    install_mysql
    mod_mysql_myconf
    init_mysql
    create_mysql_service
    set_mysql_env

    # 启动mysql、设置root用户密码，并删除数据库里面密码为空的不安全用户
    /etc/init.d/mysql${MYSQL_PORT} start
    check_ok
    mysqladmin -uroot password "${ROOT_PWD}" -S /tmp/mysql${MYSQL_PORT}.sock
    mysql -uroot -p${ROOT_PWD} -S /tmp/mysql${MYSQL_PORT}.sock << EOF
delete from mysql.user where password='';
flush privileges;
EOF
}

#--------------------------------- 部署选择 ---------------------------------#
main