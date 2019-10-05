## Резервное копирование  

При запуске vagrant up при помощи сценария ansible [playbooks/backup.yml](playbooks/backup.yml) с использованием ролей:
 [roles/borg_server](roles/borg_server) и [roles/borg_client](roles/borg_client) подключается репозиторий EPEL, устанавливается пакет 
 borgbackup, настраиивается доступ по ssh с машины client к server по ключам, инициализируется репозеторий borg - backup_etc_client и 
 добавляется задание на client, выполняющееся раз в 10 минут.  

```console
PLAY RECAP *********************************************************************
server                     : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
PLAY RECAP *********************************************************************
client                     : ok=9    changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

```console
[root@client ~]# crontab -l
#Ansible: etc_backup
*/10 * * * * borg create borg@server:backup_etc_client::"etc_backup-{now:\%Y-\%m-\%d_\%H:\%M:\%S}" /etc
```

```console
[root@client ~]# borg list borg@server:backup_etc_client
etc_backup-2019-10-05_15:00:02       Sat, 2019-10-05 15:00:04 [e28eda6ffef730432c4869f141ad51dcf7c5f981b62bf543144b07c139499fa3]
etc_backup-2019-10-05_15:10:01       Sat, 2019-10-05 15:10:03 [bb0b4c316174935b87d839c051d8680ba905ac3e06ef9b3d08748a2a5cc15073]
etc_backup-2019-10-05_15:20:01       Sat, 2019-10-05 15:20:03 [3378b905c5c9f5f3dc8bf04720e11661d0c6e6ac87726f527517b0994c69fb5b]
etc_backup-2019-10-05_15:30:02       Sat, 2019-10-05 15:30:03 [7b145f60fd7009f59c144720aaa4e3e4a1f9649c3b20787fe1680bc910540d0c]
```

Состояние резервных копий:  
```console
[root@client ~]# borg info borg@server:backup_etc_client
Repository ID: 8a29cc0df33a39c3b36e8e102261be2a739944e57631e983a20445d55457bcb3
Location: ssh://borg@server/./backup_etc_client
Encrypted: No
Cache: /root/.cache/borg/8a29cc0df33a39c3b36e8e102261be2a739944e57631e983a20445d55457bcb3
Security dir: /root/.config/borg/security/8a29cc0df33a39c3b36e8e102261be2a739944e57631e983a20445d55457bcb3
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
All archives:              111.19 MB             52.79 MB             11.79 MB

                       Unique chunks         Total chunks
Chunk index:                    1281                 6748
```
