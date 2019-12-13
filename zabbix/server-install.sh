#!/bin/sh
echo "docker 快速部署zabbix" &&
#scp repo.zip 到线上服务器解压替换yum仓库
#安装docker服务
rpm -qa | grep docker* || yum -y install docker-ce docker* && systemctl restart docker && systemctl enable docker && 

#部署数据库mysql
docker run --name zabbix-mysql-server --hostname zabbix-mysql-server -e MYSQL_ROOT_PASSWORD="123456" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="123456" -e MYSQL_DATABASE="zabbix" -p 3306:3306 -d mysql:5.7 --character-set-server=utf8 --collation-server=utf8_bin &&
#查看容器IP
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -a -q) && 

#部署zabbix-server
docker run  --name zabbix-server-mysql --hostname zabbix-server-mysql --link zabbix-mysql-server:mysql -e DB_SERVER_HOST="mysql" -e MYSQL_USER="zabbix" -e MYSQL_DATABASE="zabbix" -e MYSQL_PASSWORD="123456" -v /etc/localtime:/etc/localtime:ro -v /data/docker/zabbix/alertscripts:/usr/lib/zabbix/alertscripts -v /data/docker/zabbix/externalscripts:/usr/lib/zabbix/externalscripts -p 10051:10051 -d zabbix/zabbix-server-mysql &&

#部署zabbix-web-nginx
docker run --name zabbix-web-nginx-mysql --hostname zabbix-web-nginx-mysql --link zabbix-mysql-server:mysql --link zabbix-server-mysql:zabbix-server -e DB_SERVER_HOST="mysql" -e MYSQL_USER="zabbix" -e MYSQL_PASSWORD="123456" -e MYSQL_DATABASE="zabbix" -e ZBX_SERVER_HOST="zabbix-server" -e PHP_TZ="Asia/Shanghai" -p 8000:80 -p 8443:443 -d zabbix/zabbix-web-nginx-mysql &&

#部署docker-zabbbix-agent
docker run --name zabbix-agent --link zabbix-server-mysql:zabbix-server -d zabbix/zabbix-agent:latest

######################################################################################################################
#然后打开浏览器http://127.0.0.1/zabbix安装zabbix
######################################################################################################################
#被监控机
#scp repo.zip 到线上服务器解压替换yum仓库
#systemctl stop firewalld.service && setenforce 0
#rpm -Uvh http://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-agent-4.4.3-1.el7.x86_64.rpm && yum install -y zabbix-agent
#sed -i "s/Server=127.0.0.1/Server=(zabbix-serverIP)/g" /etc/zabbix/zabbix_agentd.conf
#systemctl enable zabbix-agent.service && systemctl restart zabbix-agent.service
#netstat -anpt | grep zabbix 
#yum -y install lsof && lsof -i:10050 && curl https://ip.cn
#还需要到云平台的安全策略进出口规则放行10050端口
