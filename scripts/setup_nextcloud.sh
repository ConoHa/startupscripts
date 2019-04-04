#!/bin/bash

readonly YUM_COMMAND="yum -y -q"
readonly NEXTCLOUD_ARCHIVE="nextcloud-12.0.3.tar.bz2"

${YUM_COMMAND} install https://centos7.iuscommunity.org/ius-release.rpm

${YUM_COMMAND} install php56u php56u-devel php56u-cli php56u-gd php56u-imap php56u-mbstring php56u-mysql php56u-mysqli php56u-mcrypt php56u-pdo php56u-xml

sed -i /etc/php.ini -e "s/;mbstring.language = Japanese/mbstring.language = Neutral/"
sed -i /etc/php.ini -e "s/;mbstring.http_input =/mbstring.language = Neutral/"
sed -i /etc/php.ini -e "s/;mbstring.encoding_translation = Off/mbstring.encoding_translation = Off/"
sed -i /etc/php.ini -e "s/;mbstring.internal_encoding =/mbstring.internal_encoding = UTF-8/"


${YUM_COMMAND} install httpd
sed -i /etc/httpd/conf/httpd.conf -e "s/Options Indexes FollowSymLinks/Options -Indexes +FollowSymlinks/"
rm /etc/httpd/conf.d/welcome.conf

firewall-cmd --add-service http --permanent
firewall-cmd --add-service https --permanent
firewall-cmd --reload


${YUM_COMMAND} install mariadb-server mariadb-devel


cd /var/www/html

wget https://download.nextcloud.com/server/releases/${NEXTCLOUD_ARCHIVE}
tar xf ${NEXTCLOUD_ARCHIVE}
chown -R apache:apache /var/www/html/nextcloud
rm -f ${NEXTCLOUD_ARCHIVE}


systemctl enable --now mariadb
systemctl enable --now httpd


readonly MYSQL_CMD="mysql -u root mysql"
readonly MYSQL_ROOT_PASS=`mkpasswd -s 0`
readonly MYSQL_NEXTCLOUD_USERNAME="nextcloud_user"
readonly MYSQL_NEXTCLOUD_PASS=`mkpasswd -s 0`
readonly MYSQL_NEXTCLOUD_DBNAME="nextcloud_db"

echo "GRANT ALL ON ${MYSQL_NEXTCLOUD_DBNAME}.* TO '${MYSQL_NEXTCLOUD_USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_NEXTCLOUD_PASS}';" | ${MYSQL_CMD}
echo "CREATE DATABASE ${MYSQL_NEXTCLOUD_DBNAME} DEFAULT CHARSET 'utf8'" | ${MYSQL_CMD}
echo "UPDATE user SET password=PASSWORD('$MYSQL_ROOT_PASS') WHERE User = 'root';" | ${MYSQL_CMD}

systemctl restart mariadb


IPADDRESS=`ip -4 addr show eth0 | grep "global" | awk '{print $2}' | cut -d "/" -f 1`
if [ -n "${IPADDRESS}" ];
then echo "Nextcloud URL : http://${IPADDRESS}/nextcloud" >> /root/nextcloud-configs
fi

echo "MySQL Nextcloud root password : ${MYSQL_ROOT_PASS}" >> /root/nextcloud-configs
echo "" >> /root/nextcloud-configs
echo "MySQL Nextcloud username : ${MYSQL_NEXTCLOUD_USERNAME} " >> /root/nextcloud-configs
echo "MySQL ${MYSQL_NEXTCLOUD_USERNAME} password : ${MYSQL_NEXTCLOUD_PASS}" >> /root/nextcloud-configs
echo "MySQL Nextcloud dtabase name : ${MYSQL_NEXTCLOUD_DBNAME}" >> /root/nextcloud-configs
