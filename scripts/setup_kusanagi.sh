#!/bin/bash
yum update -y

mkp="mkpasswd -l 10 -s 0"

password=`$mkp`
passphrase=`$mkp`
dbpassword=`$mkp`

expect -c "
set timeout -1
spawn kusanagi init --tz tokyo \
    --lang ja \
    --keyboard ja \
    --passwd $password \
    --phrase $passphrase \
    --dbrootpass $dbpassword \
    --nginx \
    --php7 \
    --ruby24
expect \"Which you using?(1):\"
send \"\n\"
expect \"KUSANAGI initialization completed\"
exit 0
"

cat << EOF >> /etc/motd
================================================
kusanagi user password  : $password
kusanagi user passphrase: $passphrase
MySQL root password     : $dbpassword

To delete this message: rm -f /etc/motd
================================================
EOF