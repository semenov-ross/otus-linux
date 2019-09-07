## Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл.

При старте виртуальной машины при помощи [create_service.sh](create_service.sh) устанавливается httpd,
затем в файл /usr/lib/systemd/system/httpd.service добавляется параметр %I в опцию EnvironmentFile
и переименовываем unit файл httpd.service в httpd@.service...
Создаем отдельные файлы окружения /etc/sysconfig/httpd-80 и /etc/sysconfig/httpd-8080 и указываем
в них опции запуска сервера с отдельными конфигурационными файлами OPTIONS="-f conf/httpd-80.conf" и OPTIONS="-f conf/httpd-8080.conf".  
После этого создаем отдельные конфигурационных файла для каждого инстанса сервера 
/etc/httpd/conf/httpd-80.conf и /etc/httpd/conf/httpd-8080.conf и указываем на каких портах запускать и какой PID файл использовать.   
Запускаем два инстанса сервера systemctl start httpd@80 и systemctl start httpd@8080  

Получаем результат запуска:  
```console
[root@lvm ~]# ss -lpnt | grep httpd
LISTEN     0      128         :::8080                    :::*                   users:(("httpd",pid=3970,fd=4),("httpd",pid=3969,fd=4),("httpd",pid=3968,fd=4),("httpd",pid=3967,fd=4),("httpd",pid=3966,fd=4),("httpd",pid=3965,fd=4))
LISTEN     0      128         :::80                      :::*                   users:(("httpd",pid=3963,fd=4),("httpd",pid=3962,fd=4),("httpd",pid=3961,fd=4),("httpd",pid=3960,fd=4),("httpd",pid=3959,fd=4),("httpd",pid=3958,fd=4))
```
