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
IS_FDFS=$3

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

#--------------------------------- 安装依赖包 ---------------------------------#

# 安装依赖包
for p in make cmake gcc gcc-c++ openssl openssl-devel pcre pcre-devel patch ; do
    myum $p
done

#--------------------------------- 程序模块 ---------------------------------#
# 开始安装
install_nginx() {

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "创建nginx用户"
    useradd nginx

    echo "解压并打补丁"
    cd ${PACKAGE_DIR}
    tar -zxf ${PACKAGE_DIR}/nginx-[0-9]*.tar.gz
    check_ok

    unzip ${PACKAGE_DIR}/nginx_upstream*.zip
    check_ok

    echo "开始打补丁"
    cd ${PACKAGE_DIR}/nginx-[0-9]*[0-9]
    patch -p0 < ${PACKAGE_DIR}/nginx_upstream_check_module-master/check_1.11.1+.patch
    check_ok

    echo "开始执行编译安装"
    if [[ ${IS_FDFS} = "Y" || ${IS_FDFS} = "y" ]]; then
        # 解压fdfs模块、缓存模块
        unzip ${PACKAGE_DIR}/fastdfs-nginx-module-master.zip -d ${PACKAGE_DIR}
        tar -zxf ${PACKAGE_DIR}/ngx_cache_purge-2.3.tar.gz -C ${PACKAGE_DIR}
        #  编译
        ./configure --prefix=/usr/local/nginx --sbin-path=/usr/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf \
        --error-log-path=/usr/local/nginx/logs/error.log --http-log-path=/usr/local/nginx/logs/access.log --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx \
        --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module \
        --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module \
        --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-mail --with-mail_ssl_module \
        --with-file-aio --with-ipv6 --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
        --with-stream --add-module=${PACKAGE_DIR}/nginx_upstream_check_module-master \
        --add-module=${PACKAGE_DIR}/fastdfs-nginx-module-master/src --add-module=${PACKAGE_DIR}/ngx_cache_purge-2.3
    else
        ./configure --prefix=/usr/local/nginx --sbin-path=/usr/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf \
        --error-log-path=/usr/local/nginx/logs/error.log --http-log-path=/usr/local/nginx/logs/access.log \
        --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx \
        --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module \
        --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module \
        --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-mail --with-mail_ssl_module \
        --with-file-aio --with-ipv6 --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
        --with-stream --add-module=${PACKAGE_DIR}/nginx_upstream_check_module-master
        check_ok
    fi

    make && make install
    check_ok

    echo "创建所需文件夹"
    dir_exists /usr/local/nginx/logs
    dir_exists /var/cache/nginx
}

# 配置NGINX
nginx_conf() {
    cd /usr/local/nginx/conf
    cp -a nginx.conf nginx.conf_bak
    # read -p "请开启新窗口对${NGINX_CONF_DIR}目录下的配置文件做修改,此窗口不要关闭,修改后按任意键继续." var
    egrep -v '#|^$' ${PACKAGE_DIR}/nginx.conf >$/usr/local/nginx/conf/nginx.conf
    egrep -v '#|^$' ${PACKAGE_DIR}/vhosts.conf >$/usr/local/nginx/conf/vhosts.conf
}

# Main函数入口
main(){

    install_nginx
    # nginx_conf
}

#--------------------------------- 部署选择 ---------------------------------#
main