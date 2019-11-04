## LDAP. Централизованная авторизация и аутентификация.

При запуске vagrant up создатся два хоста ipaserver и ipaclient.

```console
Current machine states:

ipaserver                 running (virtualbox)
ipaclient                 running (virtualbox)
```
При помощи сценария ansible [playbooks/free-ipa.yml](playbooks/free-ipa.yml) с использованием ролей
[roles/ipa-server](roles/ipa-server) и [roles/ipa-client](roles/ipa-client):  
 - Устанавливается FreeIPA сервер  
 - В файл /etc/hosts добавляются ipaserver.otus.lan и ipaclient.otus.lan  
 - Настраивается FreeIPA сервер  

```console
PLAY RECAP *********************************************************************
ipaserver.otus.lan         : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
 - Устанавливается FreeIPA клиент  
 - В файл /etc/hosts добавляются ipaserver.otus.lan и ipaclient.otus.lan  
 - Настраивается FreeIPA клиент  
 - Генерируются rsa ключи  
 - Добавляется тестовый пользователь Maks Otus  

```console
PLAY RECAP *********************************************************************
ipaclient.otus.lan         : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Тестовый пользователь авторизуется по ssh-ключу:

```console
[root@ipaclient ~]# ssh -i ~/.ssh/id_rsa_maks_otus maks.otus@ipaserver.otus.lan
Creating home directory for maks.otus.
-sh-4.2$ id
uid=1547600001(maks.otus) gid=1547600001(maks.otus) groups=1547600001(maks.otus) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```
