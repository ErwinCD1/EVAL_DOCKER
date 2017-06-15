#SCRIPT INIT EVAL LAURE & ERWIN#

if [-f dockerFile_rancher]; then
	 sudo rm -rf dockerFile_rancher
fi

if [-f dockerFile_apache]; then
	 sudo rm -rf dockerFile_apache
fi

# Stop all containers
docker stop $(docker ps -a -q)
# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)

touch dockerFile_rancher
touch dockerFile_apache
touch cronTab
touch index_apache

echo "
<html><head><meta charset="UTF-8"></head><style>.footer {position: absolute;right: 0;bottom: 0;left: 0;padding: 1rem;background-color: #efefef;text-align: center;}h1{text-align: center;color: #908BFF;font-size: 2.5em;}p{font-size: 1em;text-align: justify;}@import 'http://www.boeddo.nl/box/css/reset.css';body {background: #f4f4f4 url(http://www.boeddo.nl/box/img/bg.png);}#header_holder {width: 100%;position: fixed;top: 0px;left: 0;background: #222;z-index: 100;}#header {width: 100%;margin: auto;height: 56px;position: relative;}#pink {float: left;width: 10%;height: 56px;border-bottom: 4px solid #ff0dd0;}#blue {float: left;width: 30%;height: 56px;border-bottom: 4px solid #3bb9ff;}#green {float: left;width: 15%;height: 56px;border-bottom: 4px solid #62C506;}#orange {float: left;width: 20%;height: 56px;border-bottom: 4px solid orange;}#blue2 {float: left;width: 5%;height: 56px;border-bottom: 4px solid #3bb9ff;}#purple2 {float: left;width: 20%;height: 56px;border-bottom: 4px solid #ff0dd0;}</style><body><div id='header_holder'><div id='header'><div id='blue'></div><div id='pink'></div><div id='green'></div><div id='orange'></div><div id='blue2'></div><div id='purple2'></div></div></div><br><br><h1> Bonjour Jeune Homme, </h1><p> Vous êtes arrivé sur notre serveur Apache :) </p> <div class="footer"> © Réalisé par Erwin et Laure - Dev9 </div></body></html>
"> index_apache

echo '0 3 * * * logwatch --detail low --format text > /home/logwatch.log
0 4 * * * /usr/bin/rkhunter --cronjob --update --quiet
0 4 * * * /usr/bin/chkrootkit > /dev/null
'> cronTab

#echo 'FROM rancher/server:latest
#WORKDIR /usr/local/apache2/htdocs
#EXPOSE 80
#RUN apt-get -y update && apt-get install -y nano cron logwatch fail2ban rkhunter chkrootkit ufw
#ADD cronTab /etc/cron.d/hello-cron
#RUN chmod 0644 /etc/cron.d/hello-cron
#RUN touch /var/log/cron.log
#CMD cron && tail -f /var/log/cron.log' > dockerFile_rancher

echo 'FROM httpd:latest
WORKDIR /usr/local/apache2/htdocs
EXPOSE 80
RUN apt-get -y update && apt-get install -y apache2 && a2enmod rewrite headers && mkdir /var/www/webapp && sed -i -e "s/\/var\/www\/html/\/var\/www\/webapp/g" /etc/apache2/sites-available/000-default.conf && apt-get install -y nano cron logwatch fail2ban rkhunter chkrootkit ufw mysql-client
ADD cronTab /etc/cron.d/hello-cron
ADD index_apache /usr/local/apache2/htdocs/index.html
RUN chmod 0644 /etc/cron.d/hello-cron
RUN touch /var/log/cron.log
CMD cron && tail -f /var/log/cron.log' > dockerFile_apache

#docker build -f dockerFile_rancher -t rancher .
docker build -f dockerFile_apache -t apache .


docker run --name mysql -e MYSQL_ROOT_PASSWORD=0000 -d mysql:latest
docker run --name myadmin -d --link $(docker ps -aqf "name=mysql"):db -p 4000:80 phpmyadmin/phpmyadmin
docker run --name apache --link $(docker ps -aqf "name=mysql") -p 5000:80 -d apache
#docker run --name rancher --link $(docker ps -aqf "name=apache") --link $(docker ps -aqf "name=myadmin") --link $(docker ps -aqf "name=mysql") -p 7000:80 -d rancher
docker run -d --restart=unless-stopped   -p 8080:8080 rancher/server
