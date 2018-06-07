#!/bin/bash

##############################################################################
#   脚本名称: redis.sh 
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
REDIS_NUM=$5
REDIS_PORTS=$6
REDIS_BIND=$7
REDIS_REQUIREPASS=$8
REDIS_MAXCLIENTS=$9
REDIS_MAXMEMORY=${10}


PRI_REDIS_IP=${11}
PRI_REDIS_PORT=${12}
REDIS_MASTERAUTH=${13}
AUTHPASS=${14}

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

#--------------------------------- 部署实例及服务 ---------------------------------#
deployment_redis_args_pbrcm() {

    /bin/mkdir -p ${INSTALL_DIR}/redisdb/{conf,log,${REDIS_PORT}}
    if [ "${REDIS_PORT}" != "" ]; then
    cat << EOF >> ${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf
bind ${REDIS_BIND}
protected-mode yes
port ${REDIS_PORT}
tcp-backlog 511
timeout 10
tcp-keepalive 300
daemonize yes
supervised no
pidfile ${INSTALL_DIR}/redisdb/redis_${REDIS_PORT}.pid
loglevel notice
logfile ${INSTALL_DIR}/redisdb/log/redis_${REDIS_PORT}.log
databases 16
#save 900 1
#save 300 10
#save 60 10000
Revenp-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ${INSTALL_DIR}/redisdb/${REDIS_PORT}
#slaveof <masterip> <masterport>
#masterauth <master-password>
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
requirepass ${REDIS_REQUIREPASS}
maxclients ${REDIS_MAXCLIENTS}
maxmemory ${REDIS_MAXMEMORY}gb
appendonly no
#appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
cluster-enabled yes
cluster-config-file nodes-${REDIS_PORT}.conf
cluster-node-timeout 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
EOF

    cat << EOF >> /etc/init.d/redis_${REDIS_PORT}
#!/bin/sh
###############
# SysV Init Information
# chkconfig: - 58 74
# description: redis_${REDIS_PORT} is the redis daemon.
### BEGIN INIT INFO
# Provides: redis_8881
# Required-Start: \$network \$local_fs \$remote_fs
# Required-Revenp: \$network \$local_fs \$remote_fs
# Default-Start: 2 3 4 5
# Default-Revenp: 0 1 6
# Should-Start: \$syslog \$named
# Should-Revenp: \$syslog \$named
# Short-Description: start and Revenp redis_8881
# Description: Redis daemon
### END INIT INFO
EXEC=/usr/local/bin/redis-server
CLIEXEC=/usr/local/bin/redis-cli
PIDFILE=${INSTALL_DIR}/redisdb/redis_${REDIS_PORT}.pid
CONF="${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf"
REDISPORT="${REDIS_PORT}"
case "\$1" in
    start)
        if [ -f \$PIDFILE ]
        then
            echo "\$PIDFILE exists, process is already running or crashed"
        else
            echo "Starting Redis server..."
            \$EXEC \$CONF
        fi
        ;;
    Revenp)
        if [ ! -f \$PIDFILE ]
        then
            echo "\$PIDFILE does not exist, process is not running"
        else
            PID=\$(cat \$PIDFILE)
            echo "Revenpping ..."
            \$CLIEXEC -p \$REDISPORT -a ${REDIS_REQUIREPASS} shutdown
            while [ -x /proc/\${PID} ]
            do
                echo "Waiting for Redis to shutdown ..."
                sleep 1
            done
            echo "Redis Revenpped"
        fi
        ;;
    status)
        PID=\$(cat \$PIDFILE)
        if [ ! -x /proc/\${PID} ]
        then
            echo 'Redis is not running'
        else
            echo "Redis is running (\$PID)"
        fi
        ;;
    restart)
        \$0 Revenp
        \$0 start
        ;;
    *)
        echo "Please use start, Revenp, restart or status as first argument"
        ;;
esac
EOF
    /bin/chmod +x /etc/init.d/redis_${REDIS_PORT}
    /bin/chown -R redis:redis ${INSTALL_DIR}/redisdb
    /bin/chown -R redis:redis /etc/init.d/redis_${REDIS_PORT}
    fi
    echo "New redis Config File PATH:    ${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf"
    echo "New redis startup script PATH: /etc/init.d/redis_${REDIS_PORT}"
    echo "USAGE: /etc/init.d/redis_${REDIS_PORT} [ start | Revenp | restart ]"

}

#--------------------------------- redis模块 ---------------------------------#
# 开始安装redis
install_redis() {

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "创建安装目录"
    dir_exists ${INSTALL_DIR}

    echo -e "${green}开始安装依赖包... ${none}"
    # Redis 2.4版本之后，默认使用jemalloc来做内存管理，因为jemalloc被证明解决fragmentation problems（内存碎片化问题）比libc更好。
    # 但是如果你又没有jemalloc而只有libc，当make出错时，你可以加这么一个参数即可 make MALLOC=libc
    for p in make cmake gcc gcc-c++ libstdc libstdc++-devel glibc glibc-devel zlib zlib-devel tcl tcl-devel; do
        myum $p
    done

    echo -e "${green}开始解压、部署redis... ${none}"
    sleep 1
    cd ${PACKAGE_DIR}
    tar -xf ${PACKAGE_DIR}/redis-[0-9]*.tar.gz
    check_ok
    cd ${PACKAGE_DIR}/redis-[0-9]*[0-9]
    make && make install
    check_ok
}

install_instance() {

    echo -e "${green}部署redis服务... ${none}"
    # read -p "请输入redis实例个数：" REDIS_NUM 
    # read -p "请输入redis起始端口：" REDIS_PORTS
    # read -p "请输入redis绑定IP(0.0.0.0表示任意)：" REDIS_BIND
    # read -p "请输入redis登入密码：" REDIS_REQUIREPASS
    # read -p "请输入redis允许的最大客户端连接数：" REDIS_MAXCLIENTS
    # read -p "请输入redis实例最大可用内存(单位为g)：" REDIS_MAXMEMORY

    if [ ${REDIS_NUM} -eq 1 ]; then
        REDIS_PORT=${REDIS_PORTS}
        deployment_redis_args_pbrcm
        sed -i '/^cluster/s/^/#/' ${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf
        check_ok    
    else
        # 部署多个redis实例时，如果属于redis集群，则注释掉登陆密码
        for ((i=0; i<${REDIS_NUM}; i++)); do
            REDIS_PORT=`expr ${REDIS_PORTS} + ${i}`
            deployment_redis_args_pbrcm
            check_ok
            sleep 1

            if [ ${MENU_CHOOSE} = 3 ]; then
                sed -i '/^requirepass/s/^/#/' ${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf
            else
                sed -i '/^cluster/s/^/#/' ${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf
            fi
        done
    fi
}


set_redis_slave() {

    # read -p "请输入主redis的IP地址：" PRI_REDIS_IP
    # read -p "请输入主redis的端口号：" PRI_REDIS_PORT
    # read -p "请输入主redis的登陆密码：" REDIS_MASTERAUTH

    sed -i "/^#slaveof/a\slaveof ${PRI_REDIS_IP} ${PRI_REDIS_PORT}" ${INSTALL_DIR}/redisdb/conf/${REDIS_PORTS}.conf
    sed -i "/^#masterauth/a\masterauth ${REDIS_MASTERAUTH}" ${INSTALL_DIR}/redisdb/conf/${REDIS_PORTS}.conf
}

#-------------------------------- Cluster模块 --------------------------------#
# 开始安装ruby
install_ruby() {
    rpm -qa |grep ruby |xargs rpm -e --nodeps
    mkdir /usr/local/ruby
    echo -e "${green}解压并部署ruby ${none}"
    sleep 1
    cd ${PACKAGE_DIR}
    tar -zxvf ${PACKAGE_DIR}/ruby-[0-9]*.tar.gz
    check_ok
    cd ${PACKAGE_DIR}/ruby-[0-9]*[0-9]
    ./configure --prefix=/usr/local/ruby
    check_ok
    make && make install
    check_ok

    cp ruby /usr/local/bin
    sleep 2
    ln -s /usr/local/bin/ruby /usr/bin/ruby
    # 验证安装
    /usr/local/bin/ruby -v
}

# 开始安装rubygems
install_rubygems() {
    echo -e "${green}解压并部署rubygems ${none}"
    sleep 1
    cd ${PACKAGE_DIR}
    tar -zxvf ${PACKAGE_DIR}/rubygems-[0-9]*.tgz
    check_ok
    cd ${PACKAGE_DIR}/rubygems-[0-9]*[0-9]
    /usr/local/bin/ruby setup.rb
    check_ok

    cp bin/gem /usr/local/bin
    sleep 2
    /usr/local/bin/gem -v

    # 在gems中安装ruby访问redis的接口插件
    /usr/local/bin/gem install -l ${PACKAGE_DIR}/redis-[0-9]*.gem
    check_ok
}

# 启动redis
redis_start() {
    for ((i=0; i<${REDIS_NUM}; i++)); do
        REDIS_PORT=`expr ${REDIS_PORTS} + ${i}`
        /etc/init.d/redis_${REDIS_PORT} start
        sleep 1
    done
}

# 开始创建redis集群
redis_cluster() {
    cd ${PACKAGE_DIR}/redis-[0-9]*[0-9]
    cp src/redis-trib.rb /usr/local/bin

    echo -e "${green}开始创建集群... ${none}"
    sleep 2
    cluster_node=""
    for ((i=0; i<${REDIS_NUM}; i++)); do
        REDIS_PORT=`expr ${REDIS_PORTS} + ${i}`
        cluster_node=${cluster_node}"127.0.0.1:${REDIS_PORT} "
        sleep 1
    done
    echo "yes" | /usr/local/bin/redis-trib.rb create --replicas 1 ${cluster_node} & --stdin &>/dev/null
    sleep 5
    echo -e "${green}检查集群信息如下: ${none}"
    redis-trib.rb check 127.0.0.1:${REDIS_PORTS}
}

# 添加集群安全认证
cluster_auth() {
    # read -p "请输出集群认证密码：" AUTHPASS
    for ((i=0; i<${REDIS_NUM}; i++)); do
        REDIS_PORT=`expr ${REDIS_PORTS} + ${i}`
        # 在配置文件最后添加认证密钥
        # ${INSTALL_DIR}/redisdb目录在部署redis服务时为脚本自动创建
        echo "masterauth \"${AUTHPASS}\"" >>${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf
        echo "requirepass \"${AUTHPASS}\"" >>${INSTALL_DIR}/redisdb/conf/${REDIS_PORT}.conf
        check_ok

        # 修改启动脚本中的shutdown命令密码
        sed -i -r "/REDISPORT/s/x+/${AUTHPASS}/" /etc/init.d/redis_${REDIS_PORT}
        sleep 1
    done

    # 在集群脚本添加密码配置,如果配置了redis的连接密码，则需要执行以下命令。
    sed  -i -r "/password/s/nil/${AUTHPASS}/" /usr/local/ruby/lib/ruby/gems/[0-9]*[0-9]/gems/redis-[0-9]*[0-9]/lib/redis/client.rb
}

# 集群主函数入口
cluster_main(){
    install_redis
    install_instance
    install_ruby
    install_rubygems
    #cluster_auth
    redis_start
    redis_cluster
}


#--------------------------------- 部署选择 ---------------------------------#
# read -p "请输入编号选择【1：Single  2：Slave 3：Cluster 4: Instance】 (1/2/3/4)：" MENU_CHOOSE

case "${MENU_CHOOSE}" in
    1|Single|single)    
        install_redis
        install_instance
        ;;
    2|Slave|slave)
        install_redis
        install_instance
        set_redis_slave
        ;;
    3|Cluster|cluster)
        cluster_main
        ;;
    4|Instance|instance)
        install_instance
        ;;
    *)
        echo $"Usage: $0 {<single | slave | cluster | instance>}."
        exit 1
        ;;
esac