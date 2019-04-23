#!/bin/bash
# docker_tomcat.sh

v_webapp=''
v_port=''
v_env=''
v_dit=''

while getopts "a:p:e:d" arg
do
	case $arg in
		a)
			v_webapp=$OPTARG;
			;;
		p)
			v_port=$OPTARG;
			;;
		e)
			v_env=$OPTARG;
			;;
		d)
			v_dit='true';
			;;
		?)
			echo "unkonw argument $arg"
			exit 1
			;;
	esac
done

if [ "$v_webapp"x = ""x ] || [ "$v_env"x = ""x ] || [ "$v_port"x = ""x ]; then
	echo "缺乏参数:"
	echo "	-a: 应用目录"
	echo "	-p: 端口"
	echo "	-e: 环境"
	echo "	-d: 后端运行"
	exit 1;
fi

echo "应用目录: webapps/$v_webapp"
echo "端口: $v_port"
echo "环境: $v_env"

# 替换server.xml
#sed "s/webapps\/[0-9]*/webapps\/$v_webapp/g" -i server.xml

v_d_webapps="-v /usr/docker/tomcat/esp/webapps:/webapps"
v_d_logs="-v /usr/docker/tomcat/esp/logs:/usr/local/tomcat/logs"
v_f_server_xml="-v /usr/docker/tomcat/esp/server.xml:/usr/local/tomcat/conf/server.xml"

echo "运行docker命令:"
echo "docker run -p $v_port:8080 $v_d_webapps $v_d_logs $v_f_server_xml --env spring.profiles.active=$v_env S249:8081/tomcat"

if [ "$v_dit"x = ""x ]; then
	# 前台运行
	docker run -p $v_port:8080 $v_d_webapps $v_d_logs $v_f_server_xml --env spring.profiles.active=$v_env S249:8081/tomcat
else
	# 后台运行
	docker run -p $v_port:8080 $v_d_webapps $v_d_logs $v_f_server_xml --env spring.profiles.active=$v_env -dit S249:8081/tomcat
fi

echo "运行docker完成"