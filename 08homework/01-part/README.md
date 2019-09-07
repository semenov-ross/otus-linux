##  Cервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова.  

При запуске виртуальной машины при помощи [create_service.sh](create_service.sh) создаётися сервис [pars_log.service](pars_log.service),
запускающий скрипт [pars_log.sh](pars_log.sh), параметры которого указываются в [pars_log.sysconfig](pars_log.sysconfig)
и добавляется таймер [pars_log.timer](pars_log.timer).  

Видим запущенный сервис:
```console
[root@lvm ~]# systemctl status pars_log.service 
● pars_log.service - Monitoring systemlog
   Loaded: loaded (/usr/lib/systemd/system/pars_log.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2019-09-07 07:43:31 UTC; 20s ago
 Main PID: 4657 (pars_log.sh)
   CGroup: /system.slice/pars_log.service
           ├─4657 /bin/bash /vagrant/pars_log.sh /var/log/messages systemd
           ├─4660 /bin/bash /vagrant/pars_log.sh /var/log/messages systemd
           ├─4661 tail -n +1328 /var/log/messages
           └─8922 /bin/bash /vagrant/pars_log.sh /var/log/messages systemd

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
```

Можно посмотреть список таймеров:  

```console
[root@lvm ~]# systemctl list-timers 
NEXT                         LEFT     LAST                         PASSED    UNIT                         ACTIVATES
Sat 2019-09-07 07:24:30 UTC  13s ago  Sat 2019-09-07 07:24:43 UTC  10ms ago  pars_log.timer               pars_log.service
Sun 2019-09-08 07:13:25 UTC  23h left Sat 2019-09-07 07:13:25 UTC  11min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.servi

2 timers listed.
Pass --all to see loaded but inactive timers, too.
```
И статус таймера pars_log.timer:  
```console
[root@lvm ~]# systemctl status pars_log.timer
● pars_log.timer - Timer for run pars_log.service every 30 sec
   Loaded: loaded (/usr/lib/systemd/system/pars_log.timer; enabled; vendor preset: disabled)
   Active: active (waiting) since Sat 2019-09-07 06:59:19 UTC; 28min ago

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
```
В системном логе видим результат работы сервиса:
```console
[root@lvm ~]# tail -5 /var/log/messages 
Sep  7 07:30:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:29:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:28:01 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:28:01 localhost systemd: Starting Monitoring systemlog...
Sep  7 07:30:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:29:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:29:01 localhost systemd: Started Monitoring systemlog.
Sep  7 07:30:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:29:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:29:01 localhost systemd: Starting Monitoring systemlog...
Sep  7 07:30:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:30:01 localhost systemd: Started Monitoring systemlog.
Sep  7 07:30:02 localhost root: word "systemd" found in /var/log/messages: Sep  7 07:30:01 localhost systemd: Starting Monitoring systemlog...111
```
