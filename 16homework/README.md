## Сбор и анализ логов.  

При запуске vagrant up при помощи сценария ansible [playbooks/weblogelk.yml](playbooks/weblogelk.yml) с использованием ролей:
[roles/nginx](roles/nginx), [roles/rsyslog](roles/rsyslog) и [roles/elk](roles/elk) создатся три виртуальные машины web, log и elk.

```console
PLAY RECAP *********************************************************************
web                        : ok=22   changed=21   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
PLAY RECAP *********************************************************************
log                        : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
PLAY RECAP *********************************************************************
elk                        : ok=15   changed=12   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

При конфигурировании хоста web добавляется правило аудита:

-w /etc/nginx/nginx.conf -p wa

Хост передает логи аудита в rsuslog посредством модуля audisp syslog (/etc/audisp/plugins.d/syslog.conf):

active = yes
direction = out
path = builtin_syslog
type = builtin.
args = LOG_LOCAL6
format = string
  
rsyslog передаёт логи audit на удалённый сервер log (/etc/rsyslog.conf):  

local6.* @192.168.11.102:514

локально логи audit не сохраняются (/etc/audit/auditd.conf):  

write_logs = no

в rsyslog.conf настроено сохранение критичных логов локально и для пересылки на удалённый сервер log:  

*.crit /var/log/critical
*.crit @192.168.11.102:514

filebeat установлен для пересылки логов nginx в logstash на хост elk (/etc/filebeat/filebeat.yml):  

    output.logstash:
      hosts: ["192.168.11.103:5044"]

Подключен модуль filebeat nginx (/etc/filebeat/modules.d/nginx.yml):

    - module: nginx
      access:
        enabled: true
        var.paths: ["/var/log/nginx/access.log"]
      error:
        enabled: true
        var.paths: ["/var/log/nginx/error.log"]


Сервер rsyslog настроен для приёма сообщений по протоколам tcp и udp:

    # Provides UDP syslog reception
    $ModLoad imudp
    $UDPServerRun 514

    # Provides TCP syslog reception
    $ModLoad imtcp
    $InputTCPServerRun 514

На хосте elk eтановлены elasticsearch, logstash, kibana.  

Результаты обрашения к хосту web(192.168.11.101) можно просмотреть в Kibana по адресу http://192.168.11.103:5601  
