一键部署脚本使用说明
=====================

[TOC]

#

## 1，部署JDK

### 定义全局变量参数


| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
MODULE        |  jdk    |         模块名称
IS_DOWNLOAD   |  Y      |         是否需要下载软件包{Y/y/N/n}
JDK_VERSION   |  7      |         选择安装版本{7/8}

### 步骤一：部署JDK

```bash
curl -s http://192.168.124.169:86/software/jdk.sh | bash -s $1 $2 $3
```

>示例  
curl -s http://192.168.124.169:86/software/jdk.sh | bash -s jdk y 7

### 步骤二：生效环境变量

```bash
source /etc/profile
```

------

## 2，部署Jboss，请提前部署好JDK1.7

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE      	|   jboss      	|   模块名称
|IS_DOWNLOAD 	|   Y          	|   是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR 	|   /app       	|   安装目录
|JBOSS_NUM		|	1			|	实例个数
|HTTP_PORTS 	|	8080		|	定义HTTP起始端口(原端口为8080)
|AJP_PORTS 		|	8009		|	定义AJP起始端口(原端口为8009)
|HTTPS_PORTS 	|	8443		|	定义HTTPS起始端口(原端口为8443)
|OSGI_PORTS 	|	8090		|	定义OSGI-HTTP起始端口(原端口为8090)

### 步骤一：部署Jboss

```bash
curl -s http://192.168.124.169:86/software/jboss.sh | bash -s $1 $2 $3 $4 $5 $6 $7 $8
```

>示例  
curl -s http://192.168.124.169:86/software/jboss.sh | bash -s jboss y /app 1 8080 8009 8443 8090

### 附：后续操作

启动Jboss服务

```bash
/etc/init.d/jboss start
```

------

## 3，部署Nginx，可选择支持FDFS、缓存模块

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE        |  nginx     |    模块名称
|IS_DOWNLOAD   |  Y         |    是否需要下载软件包{Y/y/N/n}
|IS_FDFS       |  N         |    是否支持FDFS、缓存模块{Y/y/N/n}

### 步骤一：部署Nginx

```bash
curl -s http://192.168.124.169:86/software/nginx.sh | bash -s $1 $2 $3
```

>示例  
curl -s http://192.168.124.169:86/software/nginx.sh | bash -s nginx y n

------

## 4，部署Tomcat，请提前部署好JDK

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	tomcat  |      	模块名称
|IS_DOWNLOAD     	|	Y       |      	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR     	|	/app    |      	安装目录
|TOMCAT_NUM 		|	1		|		实例个数
|HTTP_PORTS 		|	8080	|		定义HTTP起始端口(原端口为8080)
|AJP_PORTS			|	8009	|		定义AJP起始端口(原端口为8009)
|SHUTDOWN_PORTS		|	8005	|		定义SHUTDOWN起始端口(原端口为8005)

### 步骤一：部署Tomcat

```bash
curl -s http://192.168.124.169:86/software/tomcat.sh | bash -s $1 $2 $3 $4 $5 $6 $7
```

>示例  
curl -s http://192.168.124.169:86/software/tomcat.sh | bash -s tomcat y /app 1 8080 8009 8005

------

## 5，部署MySQL

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	mysql       |   模块名称
|IS_DOWNLOAD     	|	Y           |   是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR     	|	/app        |   安装目录
|MYSQL_PORT			|	3306		|	服务端口
|ROOT_PWD			|	1qaz2wsx	|	设置数据库用户root密码
|BUFFER_POOL_SIZE 	|	1			|	设置innodb_buffer_pool_size大小,单位为G

### 步骤一：部署MySQL

```bash
curl -s http://192.168.124.169:86/software/mysql.sh | bash -s $1 $2 $3 $4 $5 $6
```

>示例  
curl -s http://192.168.124.169:86/software/mysql.sh | bash -s mysql y /app 3306 1qaz2wsx 1

### 步骤二：生效环境变量

```bash
source /etc/profile
```

### 附：后续操作

*部署完成后mysql服务已经启动，并且会删除数据库中所有密码为空的不安全用户*

------

## 6，部署MariaDB

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	mariadb     |  	模块名称
|IS_DOWNLOAD     	|	Y           |  	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR     	|	/app        | 	安装目录
|MARIADB_PORT		|	3306		|	服务端口
|ROOT_PWD			|	1qaz2wsx	|	设置数据库用户root密码
|BUFFER_POOL_SIZE 	|	1			|	设置innodb_buffer_pool_size大小,单位为G

### 步骤一：部署MariaDB

```bash
curl -s http://192.168.124.169:86/software/mariadb.sh | bash -s $1 $2 $3 $4 $5 $6
```

>示例  
curl -s http://192.168.124.169:86/software/mariadb.sh | bash -s mariadb y /app 3306 1qaz2wsx 1

### 步骤二：生效环境变量

```bash
source /etc/profile
```

### 附：后续操作

*部署完成后mariadb服务已经启动，并且会删除数据库中所有密码为空的不安全用户*

------

## 7，部署Redis

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	redis           |	模块名称
|MENU_CHOOSE     	|	1               |	选择部署{1/2/3/4}, 其中1代表single, 2代表slave, 3代表cluster, 4代表instance
|IS_DOWNLOAD		|	Y 				|	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR		|	/app 			|	安装目录
|REDIS_NUM			|	1				|	实例个数
|REDIS_PORTS		|	6379			|	Redis起始端口
|REDIS_BIND			|	0.0.0.0			|	绑定IP(0.0.0.0表示任意)
|REDIS_REQUIREPASS	|	1qaz2wsx		|	登入密码
|REDIS_MAXCLIENTS	|	1000			|	允许的最大客户端连接数
|REDIS_MAXMEMORY	|	1				|	实例最大可用内存,单位gb
|PRI_REDIS_IP		|	127.0.0.1		|	主Redis服务所在服务器IP地址,仅配置主从时生效
|PRI_REDIS_PORT		|	6379			|	主Redis服务的端口号,仅配置主从时生效
|REDIS_MASTERAUTH	|	1qaz2wsx		|	主Redis服务登入密码,仅配置主从时生效
|AUTHPASS			|	1qaz2wsx		| 	集群认证密码

### 步骤一：部署Redis

```bash
curl -s http://192.168.124.169:86/software/redis.sh | bash -s $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14}
```

>示例  
curl -s http://192.168.124.169:86/software/redis.sh | bash -s redis 1 y /app 1 6379 0.0.0.0 1qaz2wsx 1000 1 127.0.0.1 6379 1qaz2wsx 1qaz2wsx

------

## 8，部署CacheCloud，请提前部署好JDK和MySQL

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE         |	cachecloud  |  	模块名称
|IS_DOWNLOAD    |	Y           |  	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR    |	/app        |  	选择安装版本{7/8}
|MYSQL_IP		|	127.0.0.1	|	输入MySQL服务所在服务器IP地址	
|MYSQL_PORT		|	3306		|	输入MySQL服务端口
|CC_PWD			|	cachecloud 	|	输入MySQL数据库中cachecloud用户的密码
|CC_WEB_PORT	|	8585		|	定义Cachecloud的WEB访问端口(原端口为8585)

### 步骤一：部署CacheCloud

```bash
在Mysql中创建cachecloud库并对cachecloud用户进行授权
create database cachecloud;
grant all on cachecloud.* to cachecloud@"${CC_IP}" identified by "${CC_PWD}";
```

```bash
curl -s http://192.168.124.169:86/software/cachecloud.sh | bash -s $1 $2 $3 $4 $5 $6 $7
```

>示例  
curl -s http://192.168.124.169:86/software/cachecloud.sh | bash -s cachecloud y /app 127.0.0.1 3306 cachecloud 8585

### 步骤二：生效环境变量

```bash
source /etc/profile
```

------

## 9，部署ES及HEAD\SQL插件，请提前部署好JDK

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE         | elk             			|	模块名称
|IS_DOWNLOAD    | Y               			|	是否需要下载软件包{Y/y/N/n}
|MENU_CHOOSE    | 1               			|	选择部署{1/2/3/4}, 其中1代表es, 2代表head, 3代表sql, 4代表all
|INSTALL_DIR	| /app 						|	安装目录
|ES_DIR_NAME	| es01						|	定义ES目录名称
|HEAD_PORT		| 9100						|	定义HEAD插件WEB端口号(原端口9100)
|ES_URL			| http://172.16.16.101:9200	|	定义HEAD插件默认连接的ES地址

### 步骤一：部署ES

```bash
curl -s http://192.168.124.169:86/software/elk.sh | bash -s $1 $2 $3 $4 $5 $6 $7
```

>示例  
curl -s http://192.168.124.169:86/software/elk.sh | bash -s elk y 1 /app es01 9100 http://172.16.16.101:9200

### 步骤二：生效环境变量

```bash
source /etc/profile
```

------

## 10，离线部署ES及HEAD\SQL插件，请提前部署好JDK

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE         | es_offline             	|   模块名称
|IS_DOWNLOAD    | Y               			|	是否需要下载软件包{Y/y/N/n}
|MENU_CHOOSE    | 1               			|	选择部署{1/2/3/4}, 其中1代表es, 2代表head, 3代表sql, 4代表all
|INSTALL_DIR	| /app 						|	安装目录
|ES_DIR_NAME	| es01						|	定义ES目录名称
|HEAD_PORT		| 9100						|	定义HEAD插件WEB端口号(原端口9100)
|ES_URL			| http://172.16.16.101:9200	|	定义HEAD插件默认连接的ES地址

### 步骤一：离线部署ES

```bash
curl -s http://192.168.124.169:86/software/es_offline.sh | bash -s $1 $2 $3 $4 $5 $6 $7
```

>示例  
curl -s http://192.168.124.169:86/software/es_offline.sh | bash -s es_offline y 1 /app es01 9100 http://172.16.16.101:9200

### 步骤二：生效环境变量

```bash
source /etc/profile
```

------

## 11，部署MongoDB

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	mongodb             	|	模块名称
|MENU_CHOOSE		|	2						|	选择部署{1/2}, 其中1代表Single, 2代表ShardReplset
|IS_DOWNLOAD		|	Y 						|	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR		|	/app 					|	安装目录
|MONGODB_DATA		|	/app/mongodb/data 		|	定义数据存放目录		
|SHARD_PORTS		|	27201					|	定义shard分片起始端口
|CONFIG_PORT		|	27200					|	定义config配置端口
|MONGOS_PORT		|	27017					|	定义mongod端口
|OPLOGSIZE			|	1024					|	定义oplog大小，单位为MB
|SHARDS_NUM			|	3						|	分片数量
|MONGODB1_IP		|	172.16.16.101			|	MongoDB服务器1的IP地址
|MONGODB2_IP		|	172.16.16.102			|	MongoDB服务器2的IP地址
|MONGODB3_IP		|	172.16.16.103			|	MongoDB服务器3的IP地址

### 步骤一：部署MongoDB

```bash
curl -s http://192.168.124.169:86/software/mongodb.sh | bash -s $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}

source /etc/profile
```

### 步骤二：创建shard1副本集

```bash
curl -s http://192.168.124.169:86/software/mongodb.sh | bash -s $1 3 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}
```

### 步骤三：创建shard2副本集

```bash
curl -s http://192.168.124.169:86/software/mongodb.sh | bash -s $1 4 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}
```

### 步骤四：创建shard3副本集

```bash
curl -s http://192.168.124.169:86/software/mongodb.sh | bash -s $1 5 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}
```

### 步骤五：创建config副本集

```bash
curl -s http://192.168.124.169:86/software/mongodb.sh | bash -s $1 6 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}
```

### 步骤五：创建集群

```bash
curl -s http://192.168.124.169:86/software/mongodb.sh | bash -s $1 7 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}
```

------

## 12，部署RabbitMQ

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE         |	rabbitmq            |	模块名称
|MENU_CHOOSE	|	1					|	选择安装版本{1/2}, 其中1代表3.4.2, 2代表3.6.5
|IS_DOWNLOAD	|	Y 					|	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR	|	/app 				|	安装目录
|MQ_ADMIN_USER	|	root 				|	定义MQ管理员用户名
|MQ_ADMIN_PASS	|	1qaz2wsx			|	定义MQ管理员密码
|MQ_OPER_USER	|	sto_dev				|	定义MQ操作员用户名
|MQ_OPER_PASS	|	1qaz2wsx			|	定义MQ操作员密码

### 步骤一：部署RabbitMQ

```bash
curl -s http://192.168.124.169:86/software/rabbitmq.sh | bash -s $1 $2 $3 $4 $5 $6 $7 $8
```

>示例  
curl -s http://192.168.124.169:86/software/rabbitmq.sh | bash -s rabbitmq 1 y /app root 1qaz2wsx sto_dev 1qaz2wsx

### 步骤二：生效环境变量

```bash
source /etc/profile
```

### 附：后续操作

*部署后MQ服务已经启动，并且用户已经创建*

**集群配置参考如下**

- 集群节点互配hosts
```bash
vi /etc/hosts
172.16.16.201	node0
172.16.16.202	node1
```
- 保持两个节点的.erlang.cookie(cookie在用户家目录下)一致，且权限为400
> *注意：默认权限均为400，如果.erlang.cookie不一致，可以分别将.erlang.cookie权限设为777，然后将节点1上的scp到节点2上，再将权限置为400，如：  
node0 # chmod 777 /root/.erlang.cookie  
node0 # scp /root/.erlang.cookie 172.16.16.202:/root/   
重启MQ  
rabbitmqctl stop  
rabbitmq-server -detached*

- 将 node1 与 node0 组成集群
```bash
node1 # rabbitmqctl stop_app 
node1 # rabbitmqctl join_cluster rabbit@node0
node1 # rabbitmqctl start_app
```

- 此时 node1 与 node0 会自动建立连接；如果要使用内存节点，则可以使用
```bash
node1 # rabbitmqctl join_cluster --ram rabbit@node0
```

- 集群配置好后，可以在 RabbitMQ 任意节点上执行 `rabbitmqctl cluster_status` 来查看是否集群配置成功。

- 设置镜像队列策略，在任意一个节点上执行如下命令，将所有队列设置为镜像队列，即队列会被复制到各个节点，各个节点状态保持一致。
```bash
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
```

------

## 13，部署ZooKeeper

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	zookeeper           |  	模块名称
|IS_DOWNLOAD		|	Y 					|	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR		|	/app 				|	安装目录
|ZK_PORT			|	2181				|	定义ZK服务端口号(原端口为2181)

### 步骤一：部署ZooKeeper

```bash
curl -s http://192.168.124.169:86/software/zookeeper.sh | bash -s $1 $2 $3 $4
```

>示例  
curl -s http://192.168.124.169:86/software/zookeeper.sh | bash -s zookeeper y /app 2181

### 步骤二：生效环境变量

```bash
source /etc/profile
```

### 附：后续操作

**启动ZK**

```bash
$zookeeper/bin/zkServer.sh start
```

**集群配置参考如下**

- ZK服务器集群规模不小于3个节点，要求各服务器之间系统时间要保持一致
- 编辑ZK的配置文件zoo.cfg, 在文件尾部追加

```bash
$ vi zoo.cfg
	server.0=node0:2888:3888
    server.1=node1:2888:3888
    server.2=node2:2888:3888
```

- 在data目录下，创建文件myid，值为0，其他服务器为1、2依次增加

```bash
$ touch $zookeeper/data/myid
$ echo "0" > $zookeeper/data/myid
```
- 启动，在三个节点上分别执行命令`zkServer.sh start`
- 检验，在节点上执行命令`zkServer.sh status`

------

## 14，部署SMB

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE         | 	smb             |	模块名称
|IS_DOWNLOAD	|	Y 				|	是否需要下载软件包{Y/y/N/n}
|INSTALL_DIR	|	/app 			|	安装目录
|DATA_PATH		|	/app/samba/data	|	定义SMB数据存放目录

### 步骤一：部署SMB

```bash
curl -s http://192.168.124.169:86/software/smb.sh | bash -s $1 $2 $3 $4
```

>示例  
curl -s http://192.168.124.169:86/software/smb.sh | bash -s smb y /app /app/samba/data

### 附：后续操作

创建smb用户, 根据提示输入密码
```bash
useradd samba

/usr/local/samba/bin/pdbedit -a -u samba

```

查看用户是否创建成功

```bash
/usr/local/samba/bin/pdbedit -L
```

启动samba服务器

```bash
/usr/local/samba/sbin/smbd
```

------

## 15，部署Vsftp

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          	|	vsftpd          |  	模块名称
|IS_DOWNLOAD		|	Y 				|	是否需要下载软件包{Y/y/N/n}
|VSFTPD_DATA_PATH	|	/data 			|	定义vsftp数据存放目录
|FTP_ADMIN_USER		|	sto_app			|	定义vsftp管理员用户名
|FTP_ADMIN_PASS		|	1qaz2wsx		|	定义vsftp管理员密码
|FTP_OPER_USER		|	sto_dev			|	定义vsftp操作员用户名
|FTP_OPER_PASS		|	1qaz2wsx		|	定义vsftp操作员密码

### 步骤一：部署Vsftp

```bash
curl -s http://192.168.124.169:86/software/vsftpd.sh | bash -s $1 $2 $3 $4 $5 $6 $7
```

>示例  
curl -s http://192.168.124.169:86/software/vsftpd.sh | bash -s vsftpd y /data sto_app 1qaz2wsx sto_dev 1qaz2wsx

------

## 16，部署FDFS

### 定义全局变量参数

| 变量名 | 变量默认值 | 变量描述 |
|:------|:------:|:-----|
|MODULE          			| fdfs             		| 模块名称
|MENU_CHOOSE				| 1						| 选择部署{1/2}, 其中1代表install_tracker, 2代表install_storage
|IS_DOWNLOAD				| Y 					| 是否需要下载软件包{Y/y/N/n}
|TRACKER_SERVER_IP			| 172.16.16.101		    | 输入tracker所在服务器的IP地址，仅对安装storage生效
|TRACKER_SERVER_PORT		| 22122					| 定义tracker服务端口
|TRACKER_BASE_PATH			| /app/fastdfs/tracker 	| 定义tracker的base_path目录
|TRACKER_HTTP_PORT			| 8888					| 定义tracker的HTTP端口
|STORE_SERVER_PORT			| 23001					| 定义storage服务端口
|STORE_BASE_PATH			| /data/fastdfs/storage | 定义storage的base_path目录
|STORE_PATH_COUNT			| 10 					| 定义存储路径的个数
|STORE_BASE 				| /storage 				| 定义storage数据存储目录
|STORE_HTTP_PORT			| 8888					| 定义storage的HTTP端口
|MOD_BASE_PATH 				| /data/fastdfs/mod/ 	| 定义MOD_BASE_PATH目录

### 步骤一：部署FDFS

```bash
curl -s http://192.168.124.169:86/software/fdfs.sh | bash -s $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}
```

### 附：后续操作

启动fdfs

```bash
/etc/init.d/fdfs_trackerd start
/etc/init.d/fdfs_storaged start

```

在Storage上和入口处分别部署并配置Nginx，在此省略...

[回到顶部](#一键部署脚本使用说明)