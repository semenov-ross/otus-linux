#!/bin/bash

yum install -y epel-release -y && yum install -y spawn-fcgi php php-cli mod_fcgid httpd
cp /vagrant/spawn-fcgi.service /usr/lib/systemd/system/
sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi
sed -i 's/-P \/var\/run\/spawn-fcgi\.pid//' /etc/sysconfig/spawn-fcgi
systemctl enable spawn-fcgi
systemctl start spawn-fcgi
