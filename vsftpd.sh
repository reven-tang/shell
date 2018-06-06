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
VSFTPD_DATA_PATH=$3
FTP_ADMIN_USER=$4
FTP_ADMIN_PASS=$5
FTP_OPER_USER=$6
FTP_OPER_PASS=$7

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
# 创建用户列表
create_user_list() {
    [ ! -d /etc/vsftpd ] && mkdir -p /etc/vsftpd
    cat >> /etc/vsftpd/vuser.list << EOF
${FTP_ADMIN_USER}
${FTP_ADMIN_PASS}
${FTP_OPER_USER}
${FTP_OPER_PASS}
EOF
    check_ok

    # 使用db_load工具将vuser.list转化成数据库文件;
    # -T，将文本转化成数据库， -t 是选择读取数据文件的基本方法，-f 指定列表文件
    db_load -T -t hash -f /etc/vsftpd/vuser.list /etc/vsftpd/vuser.db
    check_ok
}

# 创建vsftpd配置文件
create_vsftpd_conf() {
    cat >> /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_file=/etc/vsftpd/vsftpd.log
xferlog_std_format=YES
chroot_local_user=YES
chroot_list_enable=NO
listen=YES
pasv_enable=YES
listen_port=21
max_clients=100
guest_enable=YES
guest_username=vsftpd
pam_service_name=vsftpd
virtual_use_local_privs=YES
user_config_dir=/etc/vsftpd/vconf
allow_writeable_chroot=YES

EOF
    check_ok
}

# 为不同的虚拟用户建立独立的配置文件
create_vuser_conf() {
    [ ! -d /etc/vsftpd/vconf ] && mkdir -p /etc/vsftpd/vconf
    cat >> /etc/vsftpd/vconf/${FTP_ADMIN_USER} << EOF 
#write_enable=NO
#cmds_allowed=ABOR,CWD,LIST,MDTM,MKD,NLST,PASS,PASV,PORT,PWD,QUIT,RETR,RNFR,RNTO,SIZE,STOR,TYPE,USER,REST,CDUP,HELP,MODE,NOOP,REIN,STAT,STOU,STRU,SYST,FEAT
file_open_mode=0444
local_max_rate=10000000
#max_clients=100
#max_per_ip=5
local_root=${VSFTPD_DATA_PATH}/pub

EOF
    check_ok

    cat >> /etc/vsftpd/vconf/${FTP_OPER_USER} << EOF 
write_enable=YES
#cmds_allowed=ABOR,CWD,LIST,MDTM,MKD,NLST,PASS,PASV,PORT,PWD,QUIT,RETR,RNFR,RNTO,SIZE,STOR,TYPE,USER,REST,CDUP,HELP,MODE,NOOP,REIN,STAT,STOU,STRU,SYST,FEAT
cmds_allowed=FEAT,REST,CWD,MDTM,NLST,PASS,PASV,PORT,PWD,QUIT,RMD,SIZE,STOR,TYPE,USER,ACCT,APPE,CDUP,HELP,MODE,NOOP,REIN,STAT,STOU,STRU,SYS
#file_open_mode=0444
#local_max_rate=1000000
#max_clients=100
#max_per_ip=5
local_root=${VSFTPD_DATA_PATH}/pub

EOF
    check_ok
}

install_vsftpd() {

    echo "开始安装依赖包..."
    for p in gcc gcc-c++ db4-utils pam-devel libcap libcap-devel tcp_wrappers tcp_wrappers-devel openssl-devel; do
        myum $p
    done

    # read -p "是否需要下载软件包(Y/N): " answer
    if [[ ${IS_DOWNLOAD} = "Y" || ${IS_DOWNLOAD} = "y" ]]; then
        echo -e "${green}正在下载软件，请稍等...${none}"
        pkg_download
        check_ok
    fi

    echo "开始安装Vsftpd..."
    cd ${PACKAGE_DIR}
    tar xvf vsftpd-3.0.3.tar.gz
    check_ok
    cd vsftpd-3.0.3
    # sed -i "s/\/usr\/lib\//\/usr\/lib64\//g" vsf_findlibs.sh 
    make && make install
    check_ok

    echo "开始建立用户列表..."
    create_user_list

    echo "开始建立PAM认证文件..."
    cat >> /etc/pam.d/vsftpd << EOF
auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser
account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser
EOF
    check_ok

    echo "建立FTP跟目录，及虚拟用户的对应系统用户..."
    mkdir -p ${VSFTPD_DATA_PATH}/pub
    useradd vsftpd -d ${VSFTPD_DATA_PATH}/pub -s /sbin/nologin
    check_ok
    chown -R vsftpd:vsftpd ${VSFTPD_DATA_PATH}

    echo "开始创建配置文件..."
    create_vsftpd_conf

    echo "开始为不同的虚拟用户建立独立的配置文件..."
    create_vuser_conf

    echo "开始创建启动脚本..."
    cp ${PACKAGE_DIR}/vsftpd /etc/init.d/
    chmod +x /etc/init.d/vsftpd
    check_ok
}

#--------------------------------- 部署选择 ---------------------------------#
install_vsftpd