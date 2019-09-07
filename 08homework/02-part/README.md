## Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл.


При старте виртуальной машины устанавливается epel и из него spawn-fcgi,
затем из [spawn-fcgi.service](spawn-fcgi.service) создается сервис spawn-fcgi и файл /etc/sysconfig/spawn-fcgi
приводится к должному виду:  
```console
[root@lvm ~]# cat /etc/sysconfig/spawn-fcgi 
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```
Так же сервис сразу активируется и стратует.  

После старта машины можем увидеть результат provision:  
```console
[root@lvm ~]# systemctl status spawn-fcgi.service 
● spawn-fcgi.service - Spawn-fcgi startup service
   Loaded: loaded (/usr/lib/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2019-09-07 09:38:09 UTC; 10min ago
 Main PID: 4098 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─4098 /usr/bin/php-cgi
           ├─4100 /usr/bin/php-cgi
           ├─4101 /usr/bin/php-cgi
           ├─4102 /usr/bin/php-cgi
           ├─4103 /usr/bin/php-cgi
           ├─4104 /usr/bin/php-cgi
           ├─4105 /usr/bin/php-cgi
           ├─4106 /usr/bin/php-cgi
           ├─4107 /usr/bin/php-cgi
           ├─4108 /usr/bin/php-cgi
           ├─4109 /usr/bin/php-cgi
           ├─4110 /usr/bin/php-cgi
           ├─4111 /usr/bin/php-cgi
           ├─4112 /usr/bin/php-cgi
           ├─4113 /usr/bin/php-cgi
           ├─4114 /usr/bin/php-cgi
           ├─4115 /usr/bin/php-cgi
           ├─4116 /usr/bin/php-cgi
           ├─4117 /usr/bin/php-cgi
           ├─4118 /usr/bin/php-cgi
           ├─4119 /usr/bin/php-cgi
           ├─4120 /usr/bin/php-cgi
           ├─4121 /usr/bin/php-cgi
           ├─4122 /usr/bin/php-cgi
           ├─4123 /usr/bin/php-cgi
           ├─4124 /usr/bin/php-cgi
           ├─4125 /usr/bin/php-cgi
           ├─4126 /usr/bin/php-cgi
           ├─4127 /usr/bin/php-cgi
           ├─4128 /usr/bin/php-cgi
           ├─4129 /usr/bin/php-cgi
           ├─4130 /usr/bin/php-cgi
           └─4131 /usr/bin/php-cgi

Sep 07 09:38:09 lvm systemd[1]: Started Spawn-fcgi startup service.
Sep 07 09:38:09 lvm systemd[1]: Starting Spawn-fcgi startup service...
```
