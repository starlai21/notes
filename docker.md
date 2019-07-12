

docker run -d -p 8089:80 -v /usr/docker/nginx/nginx.conf:/etc/nginx/nginx.conf -v /usr/docker/nginx/logs:/var/log/nginx -v /usr/docker/nginx/www/dist:/www/dist S249:8081/nginx





docker run -v /usr/docker/tomcat/webapps:/usr/local/tomcat/webapps -v /usr/docker/tomcat/server.xml:/usr/local/tomcat/conf/server.xml -v /usr/docker/tomcat/logs:/usr/local/tomcat/logs -v /usr/docker/tomcat/esp/profiles:/var/profiles -v /usr/docker/tomcat/esp/privateDir:/var/privateDir -v /usr/docker/tomcat/esp/logs:/home/unicom/logs -dit -p 8082:8080  --env spring.profiles.active=pro  S249:8081/tomcat  

docker run --name esp2 -v /usr/docker/tomcat/webapps:/usr/local/tomcat/webapps -v /usr/docker/tomcat/server.xml:/usr/local/tomcat/conf/server.xml -v /usr/docker/tomcat/logs:/usr/local/tomcat/logs -v /usr/docker/tomcat/esp/profiles:/var/profiles -v /usr/docker/tomcat/esp/privateDir:/var/privateDir -v /usr/docker/tomcat/esp/logs:/home/unicom/logs -dit -p 8084:8080  --env spring.profiles.active=pro  S249:8081/tomcat  



 cd /var/lib/docker/





docker logs --tail=100 -f tm_esp