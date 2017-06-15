#! /bin/bash
# ********************************** SCRIPT LAURE & ERWIN ********************************** #

#Vérifie si le fichier dockerFile est présent, si oui alors on le supprime
if [[-f dockerFile_apache]]; then
	 sudo rm -rf dockerFile_apache
fi

#Arrêt de tous les conteneurs et suppression des conteneurs et des images
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

#Création d'un fichier dockerFile pour apache
touch dockerFile_apache
#Création d'un fichier pour cron
touch cronTab

#Ajout des crons dans le fichier cronTab
echo '0 3 * * * logwatch --detail low --format text > /home/logwatch.log
0 4 * * * /usr/bin/rkhunter --cronjob --update --quiet
0 4 * * * /usr/bin/chkrootkit > /dev/null
'> cronTab

#Ajout du dockerFile (installation de différents paquets puis ajout du contenu du fichier cronTab dans celui du docker apache)
echo 'FROM httpd:latest
WORKDIR /usr/local/apache2/htdocs
EXPOSE 80
RUN apt-get -y update && apt-get install -y apache2 && a2enmod rewrite headers && mkdir /var/www/webapp && sed -i -e "s/\/var\/www\/html/\/var\/www\/webapp/g" /etc/apache2/sites-available/000-default.conf && apt-get install -y nano cron logwatch fail2ban rkhunter chkrootkit ufw mysql-client
ADD cronTab /etc/cron.d/hello-cron
RUN chmod 0644 /etc/cron.d/hello-cron
RUN touch /var/log/cron.log
#CMD cron && tail -f /var/log/cron.log' > dockerFile_apache

#Construction de l'image apache depuis le dockerFile apache
docker build -f dockerFile_apache -t apache .

#Création du conteneur mysql depuis le hub de docker
docker run --name mysql -e MYSQL_ROOT_PASSWORD=0000 -d mysql:latest

#Création du conteneur phpmyadmin depuis le hub de docker avec un lien vers mysql
docker run --name myadmin -d --link $(docker ps -aqf "name=mysql"):db -p 4000:80 phpmyadmin/phpmyadmin

#Création du conteneur apache avec un lien vers mysql
docker run --name apache --link $(docker ps -aqf "name=mysql") -p 5000:80 -d apache

#Création du conteneur rancher depuis le hub docker
docker run -d --restart=unless-stopped -p 8080:8080 rancher/server
