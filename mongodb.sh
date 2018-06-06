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
DOWNLOAD_URL="http://192.168.124.169:86/software/${1}"
ENV_DIR="/etc/profile"
ACTIVE=1    # 1：部署  2：卸载  3：回滚 
ACTIVE_TIME=`date '+%Y-%m-%d'`

MENU_CHOOSE=$2
IS_DOWNLOAD=$3
INSTALL_DIR=$4
MONGODB_CONF="$INSTALL_DIR/mongodb/conf"
MONGODB_DATA=$5
MONGODB_LOGS="$INSTALL_DIR/mongodb/logs"
SHARD_PORTS=$6
CONFIG_PORT=$7
MONGOS_PORT=$8
OPLOGSIZE=$9
SHARDS_NUM=${10}
MONGODB1_IP=${11}
MONGODB2_IP=${12}
MONGODB3_IP=${13}


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

#--------------------------------- 创建配置文件 ---------------------------------#

# 创建单实例配置文件
create_mongod_conf() {

    cat > ${MONGODB_CONF}/mongod.yml << EOF
systemLog:
    destination: file
    path: "${INSTALL_DIR}/mongodb/logs/mongod.log"
    logAppend: true

processManagement:
    fork: true
    pidFilePath: "${INSTALL_DIR}/mongodb/logs/mongod.pid"

net:
    bindIp: 0.0.0.0
    port: ${MONGOS_PORT}

storage:
    dbPath: "${INSTALL_DIR}/mongodb/data/mongod"
    journal:
        enabled: true
#    directoryPerDB: true
#    engine: wiredTiger
    wiredTiger:
        engineConfig:
            cacheSizeGB: 1

operationProfiling:
    slowOpThresholdMs: 100
    mode: slowOp

EOF

    echo "创建数据存放目录"
    dir_exists ${INSTALL_DIR}/mongodb/data/mongod
}


# 创建shard分片配置文件
create_shard_conf() {

    cat > ${MONGODB_CONF}/shard${SHARD_NUM}.yml << EOF
systemLog:
    destination: file
    path: "${INSTALL_DIR}/mongodb/logs/shard${SHARD_NUM}.log"
    logAppend: true

processManagement:
    fork: true
    pidFilePath: "${INSTALL_DIR}/mongodb/logs/shard${SHARD_NUM}.pid"

net:
    bindIp: 0.0.0.0
    port: ${SHARD_PORT}

storage:
    dbPath: "${INSTALL_DIR}/mongodb/data/shard${SHARD_NUM}"
    journal:
        enabled: true
#    directoryPerDB: true
#    engine: wiredTiger
    wiredTiger:
        engineConfig:
            cacheSizeGB: 1

operationProfiling:
    slowOpThresholdMs: 100
    mode: slowOp

replication:
    replSetName: sRS${SHARD_NUM}
    oplogSizeMB: ${OPLOGSIZE}
    secondaryIndexPrefetch: all

sharding:
    clusterRole: shardsvr

EOF

}

create_shards_conf() {

    for ((i=0; i<${SHARDS_NUM}; i++)); do
        SHARD_PORT=`expr ${SHARD_PORTS} + ${i}`
        SHARD_NUM=`expr 1 + ${i}`
        create_shard_conf
        sleep 1
    done

}


# 创建config配置文件
create_config_conf() {

    cat > ${MONGODB_CONF}/config.yml << EOF
systemLog:
    destination: file
    path: "${INSTALL_DIR}/mongodb/logs/config.log"
    logAppend: true

processManagement:
    fork: true
    pidFilePath: "${INSTALL_DIR}/mongodb/logs/config.pid"

net:
    bindIp: 0.0.0.0
    port: ${CONFIG_PORT}

storage:
    dbPath: "${INSTALL_DIR}/mongodb/data/config"
    journal:
        enabled: true

replication:
    replSetName: csRS

sharding:
    clusterRole: configsvr

EOF

}


# 创建mongos路由配置文件
create_mongos_conf() {

    cat > ${MONGODB_CONF}/mongos.yml << EOF
systemLog:
    destination: file
    path: "${INSTALL_DIR}/mongodb/logs/mongos.log"
    logAppend: true

processManagement:
    fork: true
    pidFilePath: "${INSTALL_DIR}/mongodb/logs/mongos.pid"

net:
    bindIp: 0.0.0.0
    port: ${MONGOS_PORT}

sharding:
    configDB: csRS/${MONGODB1_IP}:${CONFIG_PORT},${MONGODB2_IP}:${CONFIG_PORT},${MONGODB3_IP}:${CONFIG_PORT}

EOF

}



    
#--------------------------------- 创建启动服务 ---------------------------------#
# 创建单实例启动脚本
create_mongod_server() {

    cat > /etc/init.d/mongod << EOF
#!/bin/bash
# Name: 
# Version Number: 1.0.0
# Type: Shell
# Language: bash shell
# Date: 2015-12-22
# Author: STO
# Email: xx12306@163.com

################################################
# chkconfig: 2345 10 90
# description: mongod
################################################
EXEC=${INSTALL_DIR}/mongodb/bin/mongod
PIDFILE=${INSTALL_DIR}/mongodb/logs/mongod.pid
CONF="-f ${INSTALL_DIR}/mongodb/conf/mongod.yml"
PORT=${MONGOS_PORT}
################################################

case "\$1" in
    start)
        if [ -f \$PIDFILE ]
        then
            echo "\$PIDFILE exists, process is already running or crashed"
        else
        /usr/bin/numactl --interleave=all \$EXEC \$CONF &
#            \$EXEC \$CONF &
            echo -e "Starting MongoDB server...             \033[1;32m[ O K ]\033[0m"
        fi
        ;;
    stop)
        if [ ! -f \$PIDFILE ]
        then
            echo "\$PIDFILE does not exist, process is not running"
        else
            PID=\$(cat \$PIDFILE)
            \$EXEC --port \$PORT \$CONF --shutdown
            while [ -x /proc/\${PID} ]
            do
                echo "Waiting for MongoDB to shutdown ..."
                sleep 1
            done
            echo -e "Stopped MongoDB server...              \033[1;32m[ O K ]\033[0m"
        rm -f \${PIDFILE}
        fi
        ;;
    status)
        if [ ! -f \${PIDFILE} ]
        then
            echo 'MongoDB is not running'
        else
            PID=\$(cat \$PIDFILE)
            echo "MongoDB is running (\$PID)"
        fi
        ;;
    restart)
    if [ ! -f \${PIDFILE} ]
    then
        echo 'MongoDB is not running'
            \$0 start
    else
            \$0 stop
            \$0 start
    fi
        ;;
    *)
        echo \$"Usage: \$0 { start | stop | restart | status }"
        ;;
esac

EOF

}


# 创建shard分片启动脚本
create_shard_server() {

    cat > /etc/init.d/mongod_shard${SHARD_NUM} << EOF
#!/bin/bash
# Name: 
# Version Number: 1.0.0
# Type: Shell
# Language: bash shell
# Date: 2015-12-22
# Author: STO
# Email: xx12306@163.com

################################################
# chkconfig: 2345 10 90
# description: mongod
################################################
EXEC=${INSTALL_DIR}/mongodb/bin/mongod
PIDFILE=${INSTALL_DIR}/mongodb/logs/shard${SHARD_NUM}.pid
CONF="-f ${INSTALL_DIR}/mongodb/conf/shard${SHARD_NUM}.yml"
PORT=${SHARD_PORT}
################################################

case "\$1" in
    start)
        if [ -f \$PIDFILE ]
        then
            echo "\$PIDFILE exists, process is already running or crashed"
        else
        /usr/bin/numactl --interleave=all \$EXEC \$CONF &
#            \$EXEC \$CONF &
            echo -e "Starting MongoDB server...             \033[1;32m[ O K ]\033[0m"
        fi
        ;;
    stop)
        if [ ! -f \$PIDFILE ]
        then
            echo "\$PIDFILE does not exist, process is not running"
        else
            PID=\$(cat \$PIDFILE)
            \$EXEC --port \$PORT \$CONF --shutdown
            while [ -x /proc/\${PID} ]
            do
                echo "Waiting for MongoDB to shutdown ..."
                sleep 1
            done
            echo -e "Stopped MongoDB server...              \033[1;32m[ O K ]\033[0m"
        rm -f \${PIDFILE}
        fi
        ;;
    status)
        if [ ! -f \${PIDFILE} ]
        then
            echo 'MongoDB is not running'
        else
            PID=\$(cat \$PIDFILE)
            echo "MongoDB is running (\$PID)"
        fi
        ;;
    restart)
    if [ ! -f \${PIDFILE} ]
    then
        echo 'MongoDB is not running'
            \$0 start
    else
            \$0 stop
            \$0 start
    fi
        ;;
    *)
        echo \$"Usage: \$0 { start | stop | restart | status }"
        ;;
esac

EOF

}

create_shards_server() {

    for ((i=0; i<${SHARDS_NUM}; i++)); do
        SHARD_PORT=`expr ${SHARD_PORTS} + ${i}`
        SHARD_NUM=`expr 1 + ${i}`

        # 创建分片服务
        create_shard_server

        # 创建数据存放目录
        dir_exists $MONGODB_DATA/shard${SHARD_NUM}

        # 启动分片服务器
        chmod 755 /etc/init.d/mongod_shard${SHARD_NUM}
        /etc/init.d/mongod_shard${SHARD_NUM} start
        sleep 1
    done

}


# 创建config启动脚本
create_config_server() {

    cat > /etc/init.d/mongod_config << EOF
#!/bin/bash
# Name: 
# Version Number: 1.0.0
# Type: Shell
# Language: bash shell
# Date: 2015-12-22
# Author: Feng HengLian
# Email: xx12306@163.com

################################################
# chkconfig: 2345 10 90
# description: mongod
################################################
EXEC=${INSTALL_DIR}/mongodb/bin/mongod
PIDFILE=${INSTALL_DIR}/mongodb/logs/config.pid
CONF="-f ${INSTALL_DIR}/mongodb/conf/config.yml"
PORT=${CONFIG_PORT}
################################################

case "\$1" in
    start)
        if [ -f \$PIDFILE ]
        then
            echo "\$PIDFILE exists, process is already running or crashed"
        else
            \$EXEC \$CONF &
            echo -e "Starting MongoDB server...             \033[1;32m[ O K ]\033[0m"
        fi
        ;;
    stop)
        if [ ! -f \$PIDFILE ]
        then
            echo "\$PIDFILE does not exist, process is not running"
        else
            PID=\$(cat \$PIDFILE)
            \$EXEC --port \$PORT \$CONF --shutdown
            while [ -x /proc/\${PID} ]
            do
                echo "Waiting for MongoDB to shutdown ..."
                sleep 1
            done
            echo -e "Stopped MongoDB server...              \033[1;32m[ O K ]\033[0m"
        rm -f \${PIDFILE}
        fi
        ;;
    status)
        if [ ! -f \${PIDFILE} ]
        then
            echo 'MongoDB is not running'
        else
            PID=\$(cat \$PIDFILE)
            echo "MongoDB is running (\$PID)"
        fi
        ;;
    restart)
    if [ ! -f \${PIDFILE} ]
    then
        echo 'MongoDB is not running'
            \$0 start
    else
            \$0 stop
            \$0 start
    fi
        ;;
    *)
        echo \$"Usage: \$0 { start | stop | restart | status }"
        ;;
esac

EOF
}


# 创建mongos路由启动脚本
create_mongos_server() {

    cat > /etc/init.d/mongod_route << EOF
#!/bin/bash
# Name: 
# Version Number: 1.0.0
# Type: Shell
# Language: bash shell
# Date: 2015-12-22
# Author: Feng HengLian
# Email: xx12306@163.com

################################################
# chkconfig: 2345 10 90
# description: mongod
################################################
EXEC=${INSTALL_DIR}/mongodb/bin/mongos
PIDFILE=${INSTALL_DIR}/mongodb/logs/mongos.pid
CONF="-f ${INSTALL_DIR}/mongodb/conf/mongos.yml"
PORT=${MONGOS_PORT}
################################################

case "\$1" in
    start)
        if [ -f \$PIDFILE ]
        then
            echo "\$PIDFILE exists, process is already running or crashed"
        else
            \$EXEC \$CONF &
            echo -e "Starting MongoDB Route server...               \033[1;32m[ O K ]\033[0m"
        fi
        ;;
    stop)
        if [ ! -f \$PIDFILE ]
        then
            echo "\$PIDFILE does not exist, process is not running"
        else
            PID=\$(cat \$PIDFILE)
            #\$EXEC --port \$PORT \$CONF --shutdown
        /bin/kill -9 \$PID  
            while [ -x /proc/\${PID} ]
            do
                echo "Waiting for MongoDB Route to shutdown ..."
                sleep 1
            done
            echo -e "Stopped MongoDB Route server...                \033[1;32m[ O K ]\033[0m"
        rm -f \${PIDFILE}
        fi
        ;;
    status)
        if [ ! -f \${PIDFILE} ]
        then
            echo 'MongoDB Route is not running'
        else
            PID=\$(cat \$PIDFILE)
            echo "MongoDB Route is running (\$PID)"
        fi
        ;;
    restart)
    if [ ! -f \${PIDFILE} ]
    then
        echo 'MongoDB Route is not running'
            \$0 start
    else
            \$0 stop
            \$0 start
    fi
        ;;
    *)
        echo \$"Usage: \$0 { start | stop | restart | status }"
        ;;
esac

EOF

}

#--------------------------------- 程序模块 ---------------------------------#
# 开始安装
install_mongodb() {
    echo "开始安装mongodb..."
    pkg_download
    dir_exists ${INSTALL_DIR}
    cd ${PACKAGE_DIR}
    tar -zxvf ${PACKAGE_DIR}/mongodb-linux-*[0-9]*.tgz -C ${INSTALL_DIR}
    check_ok
    cd ${INSTALL_DIR}
    mv mongodb-linux-*[0-9] mongodb
    check_ok

    echo "创建mongodb的配置、数据、日志目录"
    mkdir -p ${MONGODB_CONF} ${MONGODB_DATA} ${MONGODB_LOGS}
}

# 修改系统环境变量
set_env() {
    echo "添加mongodb环境变量"
    cat >> ${ENV_DIR} << EOF

####MongoDB...
export PATH=${INSTALL_DIR}/mongodb/bin:\$PATH
EOF
    # 生效环境变量
    source ${ENV_DIR}
    check_ok
}

#----------------------------- Mongodb单实例 ------------------------------#
single_conf() {

    echo "创建配置文件"
    create_mongod_conf

    echo "创建启动脚本"
    create_mongod_server

    chmod 755 /etc/init.d/mongod

    echo "启动mongodb"
    /etc/init.d/mongod start
    check_ok
}

#--------------------------- Mongodb分片复制集 ----------------------------#
replset_shard_conf() {

    echo "创建配置文件"
    create_shards_conf
    create_config_conf
    create_mongos_conf

    echo "创建启动脚本"
    create_shards_server
    create_config_server
    create_mongos_server
    chmod 755 /etc/init.d/mongod*

    # 创建comfig配置数据存放目录
    dir_exists $MONGODB_DATA/config
}

shard1_replset() {

    # 要确保其他节点分片均已启动正常
    echo "创建shardsvr的副本集"
    SHARD_PORT=`expr ${SHARD_PORTS} + 0`
    CREATE_SHARDONE="rs.initiate({_id:\"sRS1\", members:[{_id:0,host:\"${MONGODB1_IP}:${SHARD_PORT}\"},{_id:1,host:\"${MONGODB2_IP}:${SHARD_PORT}\"},{_id:2,host:\"${MONGODB3_IP}:${SHARD_PORT}\",arbiterOnly:true}]})"
    echo "$CREATE_SHARDONE" | mongo --host ${MONGODB1_IP} --port ${SHARD_PORT} admin --shell
    check_ok
}

shard2_replset() {

    echo "创建shardsvr的副本集"
    SHARD_PORT=`expr ${SHARD_PORTS} + 1`
    CREATE_SHARDONE="rs.initiate({_id:\"sRS1\", members:[{_id:0,host:\"${MONGODB2_IP}:${SHARD_PORT}\"},{_id:1,host:\"${MONGODB3_IP}:${SHARD_PORT}\"},{_id:2,host:\"${MONGODB1_IP}:${SHARD_PORT}\",arbiterOnly:true}]})"
    echo "$CREATE_SHARDONE" | mongo --host ${MONGODB2_IP} --port ${SHARD_PORT} admin --shell
    check_ok
}

shard3_replset() {

    echo "创建shardsvr的副本集"
    SHARD_PORT=`expr ${SHARD_PORTS} + 2`
    CREATE_SHARDONE="rs.initiate({_id:\"sRS1\", members:[{_id:0,host:\"${MONGODB3_IP}:${SHARD_PORT}\"},{_id:1,host:\"${MONGODB1_IP}:${SHARD_PORT}\"},{_id:2,host:\"${MONGODB2_IP}:${SHARD_PORT}\",arbiterOnly:true}]})"
    echo "$CREATE_SHARDONE" | mongo --host ${MONGODB3_IP} --port ${SHARD_PORT} admin --shell
    check_ok
}

configsvr_replset() {

    echo "启动配置服务"
    /etc/init.d/mongod_config start
    check_ok

    # 要确保其他节点配置服务均已启动正常。
    echo "创建configsvr的副本集"
    CREATE_REPLISET="rs.initiate({_id:\"csRS\", configsvr:true,  members:[{_id:0,host:\"${MONGODB1_IP}:${CONFIG_PORT}\"},{_id:1,host:\"${MONGODB2_IP}:${CONFIG_PORT}\"},{_id:2,host:\"${MONGODB3_IP}:${CONFIG_PORT}\"}]})"
    echo "$CREATE_REPLISET" | mongo --host ${MONGODB1_IP} --port ${CONFIG_PORT} admin --shell
    check_ok
}

addshardtocluste() {
    echo "启动mongos路由服务"
    /etc/init.d/mongod_route start
    check_ok

    # 要确保其他节点路由服务均已启动正常。
    echo "分别将三个shard分片添加集群"
    for ((i=0; i<${SHARDS_NUM}; i++)); do
        SHARD_PORT=`expr ${SHARD_PORTS} + ${i}`
        SHARD_NUM=`expr 1 + ${i}`
        
        ADD_SHARD="db.runCommand( { addshard : \"sRS1/${MONGODB1_IP}:${SHARD_PORT},${MONGODB2_IP}:${SHARD_PORT},${MONGODB3_IP}:${SHARD_PORT}\",maxSize: 0,name: \"shard${SHARD_NUM}\"})"
        echo "$ADD_SHARDONE" | mongo --host ${MONGODB1_IP} --port ${MONGOS_PORT} admin --shell
        check_ok

        sleep 1
    done
}

#--------------------------------- 部署选择 ---------------------------------#
case "$MENU_CHOOSE" in
    1|Single)
        install_mongodb
        set_env
        single_conf
        ;;
    2|ShardReplset)
        install_mongodb
        set_env 
        replset_shard_conf      
        ;;
    3|shard1_replset)
        shard1_replset
        ;;
    4|shard2_replset)
        shard1_replset
        ;;
    5|shard3_replset)
        shard1_replset
        ;;
    6|configsvr_replset)
        configsvr_replset
        ;;
    7|addshardtocluste)
        addshardtocluste 
        ;;
    *)
        echo "only 1(Single) or 2(ShardReplset)"
        exit 1
        ;;
esac