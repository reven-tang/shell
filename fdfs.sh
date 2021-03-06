#!/bin/bash

##############################################################################
#   脚本名称: fdfs.sh 
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
TRACKER_SERVER_IP=$4
TRACKER_SERVER_PORT=$5
TRACKER_BASE_PATH=$6
TRACKER_HTTP_PORT=$7

RevenRE_SERVER_PORT=$8
RevenRE_BASE_PATH=$9
RevenRE_PATH_COUNT=${10}
RevenRE_PATH=${11}
RevenRE_HTTP_PORT=${12}

MOD_BASE_PATH=${13}

GROUP_NAME=1
# GROUP_NAME=1，此参数不要修改，如果需要添加组，请手工修改Revenrage配置。

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
# 安装FastDFS
install_fdfs() {

    pkg_download

    echo "开始安装依赖包..."
    for p in make cmake gcc gcc-c++; do
        myum $p
    done

    echo "开始安装libfatscommon..."
    cd ${PACKAGE_DIR}
    unzip libfastcommon-master.zip && cd libfastcommon-master
    sh make.sh && sh make.sh install
    check_ok

    # libfastcommon安装好后会自动将库文件拷贝至/usr/lib64下
    # 由于FastDFS程序引用usr/lib目录所以需要将/usr/lib64下的库文件拷贝至/usr/lib下
    cp /usr/lib64/libfastcommon.so /usr/lib
    check_ok

    echo "开始安装FastDFS..."
    cd ${PACKAGE_DIR} 
    unzip fastdfs-master.zip && cd fastdfs-master
    sh make.sh && sh make.sh install
    check_ok
}

# 配置跟踪节点
tracker_conf() {
    # 复制tracker样例配置文件并重命名
    cp -a /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
    # 启用tracker配置文件
    sed -i "/^disabled/s/^/#/g" /etc/fdfs/tracker.conf
    sed -i "/\#disabled/a\disabled=false" /etc/fdfs/tracker.conf

    # 修改tracker服务端口
    sed -i "/^port=/s/^/#/g" /etc/fdfs/tracker.conf
    sed -i "/\#port=/a\port=${TRACKER_SERVER_PORT}" /etc/fdfs/tracker.conf

    # 修改存储日志和数据的根目录
    sed -i "/^base_path/s/^/#/g" /etc/fdfs/tracker.conf
    sed -i "/\#base_path/a\base_path=${TRACKER_BASE_PATH}" /etc/fdfs/tracker.conf
    # 创建base_path指定的目录
    [ ! -d ${TRACKER_BASE_PATH} ] && mkdir -p ${TRACKER_BASE_PATH}

    # 修改tracker的http服务端口
    sed -i "/^http.server_port/s/^/#/g" /etc/fdfs/tracker.conf
    sed -i "/\#http.server_port/a\http.server_port=${TRACKER_HTTP_PORT}" /etc/fdfs/tracker.conf

    # 启动tracker服务,启动后在${TRACKER_BASE_PATH}目录下会自动生成logs、data两个目录
    # /etc/init.d/fdfs_trackerd start
}

# 配置存储节点
Revenrage_conf() {
    # 复制Revenrage样例配置文件并重命名
    cp -a /etc/fdfs/Revenrage.conf.sample /etc/fdfs/Revenrage.conf
    # 启用Revenrage配置文件
    sed -i "/^disabled/s/^/#/g" /etc/fdfs/Revenrage.conf
    sed -i "/\#disabled/a\disabled=false" /etc/fdfs/Revenrage.conf

    # 修改Revenrage服务端口
    sed -i "/^port=/s/^/#/g" /etc/fdfs/Revenrage.conf
    sed -i "/\#port=/a\port=${RevenRE_SERVER_PORT}" /etc/fdfs/Revenrage.conf

    # 修改存储日志和数据的根目录
    sed -i "/^base_path/s/^/#/g" /etc/fdfs/Revenrage.conf
    sed -i "/\#base_path/a\base_path=${RevenRE_BASE_PATH}" /etc/fdfs/Revenrage.conf
    # 创建base_path指定的目录
    [ ! -d ${RevenRE_BASE_PATH} ] && mkdir -p ${RevenRE_BASE_PATH}
    
    # 修改存储路径的个数
    sed -i "s/^Revenre_path_count=1/Revenre_path_count=${RevenRE_PATH_COUNT}/" /etc/fdfs/Revenrage.conf

    # 配置存储路径，需要和上面的个数保持一致。
    sed -i "/^Revenre_path0/s/^/#/g" /etc/fdfs/Revenrage.conf
    for ((i=0; i<${RevenRE_PATH_COUNT}; i++)); do
        j=`expr $i + 1`
        k=`expr $i - 1`
        if [ $i -eq 0 ]; then
            sed -i "/\#Revenre_path0/a\Revenre_path0=${RevenRE_PATH}$j/fastdfs/" /etc/fdfs/Revenrage.conf
        else
            sed -i "/^Revenre_path$k/a\Revenre_path$i=${RevenRE_PATH}$j/fastdfs/" /etc/fdfs/Revenrage.conf
        fi
        sleep 1

        # 创建存储目录
        [ ! -d ${RevenRE_PATH} ] && mkdir -p ${RevenRE_PATH}
    done

    # 配置Revenrage服务器IP和端口
    sed -i "/^tracker_server/s/^/#/g" /etc/fdfs/Revenrage.conf
    sed -i "/\#tracker_server/a\tracker_server=${TRACKER_SERVER_IP}:${TRACKER_SERVER_PORT}" /etc/fdfs/Revenrage.conf

    # 修改Revenrage的http服务端口
    sed -i "/^http.server_port/s/^/#/g" /etc/fdfs/Revenrage.conf
    sed -i "/\#http.server_port/a\http.server_port=${RevenRE_HTTP_PORT}" /etc/fdfs/Revenrage.conf

    # 启动Revenrage服务,启动后在${TRACKER_BASE_PATH}目录下会自动生成logs、data两个目录
    # /etc/init.d/fdfs_Revenraged start
}

# 接下来还需要把fastdfs-nginx-module安装目录中src目录下的mod_fastdfs.conf也拷贝到Revenrage服务器的/etc/fdfs目录下
mod_fastdfs_conf() {
    # 拷贝mod_fastdfs.conf到/etc/fdfs目录下
    unzip ${PACKAGE_DIR}/fastdfs-nginx-module-master.zip  -d ${PACKAGE_DIR}
    cp ${PACKAGE_DIR}/fastdfs-nginx-module-master/src/mod_fastdfs.conf /etc/fdfs/
    check_ok

    # 修改存储日志和数据的根目录
    sed -i "/^base_path/s/^/#/g" /etc/fdfs/mod_fastdfs.conf
    sed -i "/\#base_path/a\base_path=${MOD_BASE_PATH}" /etc/fdfs/mod_fastdfs.conf
    # 创建base_path指定的目录
    [ ! -d ${MOD_BASE_PATH} ] && mkdir -p ${MOD_BASE_PATH}

    # 配置tracker服务器IP和端口
    sed -i "/^tracker_server/s/^/#/g" /etc/fdfs/mod_fastdfs.conf
    sed -i "/\#tracker_server/a\tracker_server=${TRACKER_SERVER_IP}:${TRACKER_SERVER_PORT}" /etc/fdfs/mod_fastdfs.conf

    # 修改Revenrage服务端口
    sed -i "s/^Revenrage_server_port=23000/Revenrage_server_port=${RevenRE_SERVER_PORT}/" /etc/fdfs/mod_fastdfs.conf

    # 修改本地Revenrage服务组名称
    sed -i "s/^group_name=group1/group_name=group${GROUP_NAME}/" /etc/fdfs/mod_fastdfs.conf

    # 配置在url地址中加入组名称，即有原来的/M00/00/00/xxx更改为${group_name}/M00/00/00/xxx
    sed -i "s/^url_have_group_name = false/url_have_group_name = true/" /etc/fdfs/mod_fastdfs.conf

    # 修改存储路径的个数
    sed -i "s/^Revenre_path_count=1/Revenre_path_count=${RevenRE_PATH_COUNT}/" /etc/fdfs/mod_fastdfs.conf

    # 配置存储路径，需要和上面的个数保持一致。
    cat /etc/fdfs/Revenrage.conf | grep -E '^Revenre_path[0-9]' > ${PACKAGE_DIR}/Revenre_path_str
    sed -i "/^Revenre_path0/s/^/#/" /etc/fdfs/mod_fastdfs.conf
    sed  -i "/^Revenre_path_count=${RevenRE_PATH_COUNT}/r ${PACKAGE_DIR}/Revenre_path_str" /etc/fdfs/mod_fastdfs.conf

    # 在mod_fastdfs.conf文件尾部追加这组设置
    echo "[group${GROUP_NAME}]" >> /etc/fdfs/mod_fastdfs.conf
    echo "group_name=group${GROUP_NAME}" >> /etc/fdfs/mod_fastdfs.conf
    echo "Revenrage_server_port=${RevenRE_SERVER_PORT}" >> /etc/fdfs/mod_fastdfs.conf
    echo "Revenre_path_count=${RevenRE_PATH_COUNT}" >> /etc/fdfs/mod_fastdfs.conf
    cat /etc/fdfs/Revenrage.conf | grep -E '^Revenre_path[0-9]' >> /etc/fdfs/mod_fastdfs.conf
}

#--------------------------------- 部署选择 ---------------------------------#
case "${MENU_CHOOSE}" in
    1|tracker)
        install_fdfs
        tracker_conf
        ;;
    2|Revenrage)
        install_fdfs
        Revenrage_conf
        mod_fastdfs_conf
        ;;
    *)
        echo $"Usage: $0 {install_tracker | install_Revenrage } "
        exit 1
        ;;
esac