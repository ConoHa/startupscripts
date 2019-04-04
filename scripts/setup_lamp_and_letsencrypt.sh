#!/bin/bash

readonly API_TENANT_ID="$API_TENANT_ID" # テナントID
readonly API_USERNAME="$API_USERNAME" # APIユーザー名
readonly API_PASSWORD="$API_PASSWORD" # APIパスワード

readonly DOMAIN_NAME="$DOMAIN_NAME" # 使用したいドメイン名
readonly MAIL_ADDRESS="$MAIL_ADDRESS" # Let's encryptに登録するメールアドレス

readonly RECORD_TTL="3600"

readonly IP_ADDRESS=$(ip -4 addr show eth0 |grep "global" | awk '{print $2}' | cut -d "/" -f 1)


yum -y install jq


# ドメインをDNSに登録
# ConoHaのAPIを使用するためのトークンの取得
REQUEST_TOKEN_BODY="{\"auth\":{\"passwordCredentials\":{\"username\":\"${API_USERNAME}\",\"password\":\"${API_PASSWORD}\"},\"tenantId\":\"${API_TENANT_ID}\"}}" \

TYO1_RESPONSE=$( curl -f -X POST \
     -H "Accept: application/json" \
     -d "${REQUEST_TOKEN_BODY}" \
     https://identity.tyo1.conoha.io/v2.0/tokens )
TYO1_EXIT_STATUS=$?

TYO2_RESPONSE=$( curl -f -X POST \
     -H "Accept: application/json" \
     -d "${REQUEST_TOKEN_BODY}" \
     https://identity.tyo2.conoha.io/v2.0/tokens )
TYO2_EXIT_STATUS=$?

API_TOKEN=""
API_REGION=""
if [ ${TYO1_EXIT_STATUS} -eq 0 ]; then
    API_TOKEN=$(echo ${TYO1_RESPONSE}|jq --monochrome-output '."access"."token"."id"' | sed -e 's/"//g')
    API_REGION="tyo1"
elif [ ${TYO2_EXIT_STATUS} -eq 0 ]; then
    API_TOKEN=$(echo ${TYO2_RESPONSE}|jq --monochrome-output '."access"."token"."id"' | sed -e 's/"//g')
    API_REGION="tyo2"
else
    echo "failed to get token"
    exit 1
fi


# ConoHaのDNSにドメインを登録
readonly DOMAIN_UUID=$(curl -X POST  \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -H "X-Auth-Token: ${API_TOKEN}" \
     -d "{ \"name\": \"${DOMAIN_NAME}.\", \"ttl\": 3600, \"email\": \"${MAIL_ADDRESS}\", \"gslb\": 0}" \
     https://dns-service.${API_REGION}.conoha.io/v1/domains | jq --monochrome-output '."id"' | sed -e 's/"//g')

# 登録したドメインにAレコードを登録
curl -X POST \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -H "X-Auth-Token: ${API_TOKEN}" \
     -d "{ \"name\": \"${DOMAIN_NAME}.\", \"type\": \"A\", \"data\": \"${IP_ADDRESS}\", \"ttl\":${RECORD_TTL}}" \
     https://dns-service.${API_REGION}.conoha.io/v1/domains/${DOMAIN_UUID}/records


# PHPのインストール
yum -y install https://centos7.iuscommunity.org/ius-release.rpm

yum -y install php56u php56u-devel php56u-cli php56u-gd php56u-imap php56u-mbstring php56u-mysql php56u-mysqli php56u-mcrypt php56u-pdo php56u-xml


# Apacheのインストール
yum -y install httpd mod_ssl
firewall-cmd --permanent --add-service http
firewall-cmd --permanent --add-service https
firewall-cmd --reload

rm /etc/httpd/conf.d/welcome.conf

echo "<?php echo \"This is the default welcome page of LAMP image.\";" > /var/www/html/index.php
chown apache:apache /var/www/html/index.php

echo "<?php phpinfo();" > /var/www/html/phpinfo.php
chown apache:apache /var/www/html/phpinfo.php

systemctl enable --now httpd


# certbot(Let's encrypt)のインストール
yum -y install certbot


# certbotによるTLS証明書の取得
# 失敗しても4回までは自動でリトライする
RETRY=0
while :
do
    sleep 5
    certbot -n certonly --email ${MAIL_ADDRESS} -d ${DOMAIN_NAME} --webroot -w /var/www/html --agree-tos
    echo "certbot -n certonly --email ${MAIL_ADDRESS} -d ${DOMAIN_NAME} --webroot -w /var/www/html --agree-tos"

    if [ -e /etc/letsencrypt/live/${DOMAIN_NAME}/cert.pem ];then
        break;
    fi


    RETRY=$(( ${RETRY} + 1 ))
    if [ ${RETRY} -eq 4 ]; then
        echo "Failed to acquire TLS certificate" >> /etc/motd
        echo "Run manually \"certbot -n certonly --email ${MAIL_ADDRESS} -d ${DOMAIN_NAME} --webroot -w /var/www/html --agree-tos\"" >> /etc/motd
        echo "And \"systemctl restart httpd\""
        break
    fi
done


# 取得したTLS証明書の情報をhttpdの設定に書き込む
readonly HTTPD_SSL_CONF="/etc/httpd/conf.d/ssl.conf"
sed -i ${HTTPD_SSL_CONF} -e "s/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/letsencrypt\/live\/${DOMAIN_NAME}\/cert.pem/g"
sed -i ${HTTPD_SSL_CONF} -e "s/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/letsencrypt\/live\/${DOMAIN_NAME}\/privkey.pem/g"
sed -i ${HTTPD_SSL_CONF} -e "s/#SSLCertificateChainFile \/etc\/pki\/tls\/certs\/server-chain.crt/SSLCertificateChainFile \/etc\/letsencrypt\/live\/${DOMAIN_NAME}\/chain.pem/g"


# TLS証明書を自動で更新するタイマーを有効化
systemctl daemon-reload
systemctl enable --now certbot-renew.timer


# MariaDB(MySQL)のインストール
yum -y install mariadb-server mariadb-devel mysql-python
systemctl enable --now mariadb
readonly MYSQL_ROOT_PASS=$(mkpasswd -s 0)
echo "UPDATE user SET password=PASSWORD('$MYSQL_ROOT_PASS') WHERE User = 'root';" | mysql -u root mysql
service mariadb restart


# 設定情報をMOTDにまとめ
{
    echo "================================================"
    echo "DocumentRoot: /var/www/html"
    echo "URL:          https://${DOMAIN_NAME}"
    echo "phpinfo:      https://${DOMAIN_NAME}/phpinfo.php"
    echo "MySQL root password: ${MYSQL_ROOT_PASS}"
    echo ""
    echo "To delete this message: rm -f /etc/motd"
    echo "================================================"
} >> /etc/motd


systemctl restart httpd
