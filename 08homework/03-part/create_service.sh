#!/bin/bash

yum -y install httpd

sed -i 's/\/etc\/sysconfig\/httpd/\/etc\/sysconfig\/httpd-%I/' /usr/lib/systemd/system/httpd.service
mv /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service

cp /etc/sysconfig/httpd /etc/sysconfig/httpd-80
echo 'OPTIONS="-f conf/httpd-80.conf"' >> /etc/sysconfig/httpd-80
cp /etc/sysconfig/httpd /etc/sysconfig/httpd-8080
echo 'OPTIONS="-f conf/httpd-8080.conf"' >> /etc/sysconfig/httpd-8080

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-8080.conf
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-80.conf
sed -i 's/^Listen 80$/Listen 8080/' /etc/httpd/conf/httpd-8080.conf
sed -i '/^Listen 8080$/a PidFile \/var\/run\/httpd-8080.pid' /etc/httpd/conf/httpd-8080.conf

systemctl start httpd@80
systemctl start httpd@8080
