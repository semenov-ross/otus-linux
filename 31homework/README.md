## PostgreSQL cluster
Кластер PostgreSQL на Patroni

При запуске vagrant up посредством Vagrant Ansible Provisioner создаются 4 хоста: pg1(192.168.11.101), pg2(192.168.11.102), pg3(192.168.11.103) и haproxy(192.168.11.104). 
На каждом хосте pg установлен etcd и pgbouncer.

Конфиг Patroni postgresql.yml:
```console
[root@pg1 ~]# cat /opt/app/patroni/etc/postgresql.yml
scope: otus
name: pg1

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.11.101:8008

etcd:
  hosts: localhost:2379
  protocol: http

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout : 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_keep_segments: 100

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5

postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.11.101:5432
  data_dir: /var/lib/pgsql/otus/pg1/data
  bin_dir: /usr/pgsql-12/bin
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: otus
```

Конфиг etcd:
```console
[root@pg1 ~]# cat /etc/etcd/etcd.conf 
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://192.168.11.101:2379"
ETCD_LISTEN_PEER_URLS="http://192.168.11.101:2380"
ETCD_NAME="pg1"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.11.101:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.11.101:2379"
ETCD_INITIAL_CLUSTER="pg1=http://192.168.11.101:2380,pg2=http://192.168.11.102:2380,pg3=http://192.168.11.103:2380"
ETCD_INITIAL_CLUSTER_TOKEN="otus"
```

Статус кластера etcd:
```console
[root@pg1 ~]# etcdctl cluster-health
member 43d7628af44aa942 is healthy: got healthy result from http://192.168.11.101:2379
member 7d1d9c7e8377e92a is healthy: got healthy result from http://192.168.11.102:2379
member b196e323605bfbd1 is healthy: got healthy result from http://192.168.11.103:2379
cluster is healthy

```
Клиенсткие подключения настроены через HAProxy ( Веб-интерфейс [192.168.11.104:700](http://192.168.11.104:700) ):
```console
[root@haproxy ~]# cat /etc/haproxy/haproxy.cfg 
global
    maxconn 100
    log     127.0.0.1 local2

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server pg1 192.168.11.101:6543 maxconn 100 check port 8008
    server pg2 192.168.11.102:6543 maxconn 100 check port 8008
    server pg3 192.168.11.103:6543 maxconn 100 check port 8008
```
При подключение череза haproxy попадаем на лидера кластера и смотрим состояение слотов и статус репликации:
```console
[vagrant@haproxy ~]$ psql -h 192.168.11.104 -p 5000 -U postgres
Password for user postgres: 
psql (12.1)
Type "help" for help.

postgres=# select slot_name,slot_type,active from pg_replication_slots;
 slot_name | slot_type | active 
-----------+-----------+--------
 pg2       | physical  | t
 pg3       | physical  | t
(2 rows)

postgres=# select usename,application_name,client_addr,state from pg_stat_replication;
  usename   | application_name |  client_addr   |   state   
------------+------------------+----------------+-----------
 replicator | pg2              | 192.168.11.102 | streaming
 replicator | pg3              | 192.168.11.103 | streaming
(2 rows)

```
Конфиг pgbouncer.ini:
```console
[root@pg1 ~]# cat /etc/pgbouncer/pgbouncer.ini 
[databases]
* = host=127.0.0.1 port=5432
[users]
[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = *
listen_port = 6543
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
admin_users = postgres
stats_users = stats, postgres
```
Пулы соединений pgbouncer:
```console
vagrant@haproxy ~]$ psql -h 192.168.11.104 -p 5000 -U postgres pgbouncer
Password for user postgres: 
psql (12.1, server 1.12.0/bouncer)
Type "help" for help.

pgbouncer=# show pools;
-[ RECORD 1 ]---------
database   | pgbouncer
user       | pgbouncer
cl_active  | 1
cl_waiting | 0
sv_active  | 0
sv_idle    | 0
sv_used    | 0
sv_tested  | 0
sv_login   | 0
maxwait    | 0
maxwait_us | 0
pool_mode  | statement
-[ RECORD 2 ]---------
database   | postgres
user       | postgres
cl_active  | 0
cl_waiting | 0
sv_active  | 0
sv_idle    | 0
sv_used    | 1
sv_tested  | 0
sv_login   | 0
maxwait    | 0
maxwait_us | 0
pool_mode  | session
```
Режим по умолчанию для создоваемых баз pool_mode=session.

Состояние кластера Patroni:
```console
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml list
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.101 | Leader | running |  1 |         0 |
|   otus  |  pg2   | 192.168.11.102 |        | running |  1 |         0 |
|   otus  |  pg3   | 192.168.11.103 |        | running |  1 |         0 |
+---------+--------+----------------+--------+---------+----+-----------+
```
Создадим тестовую базу с одной таблицей и записью:

```console
[vagrant@haproxy ~]$ psql -h 192.168.11.104 -p 5000 -U postgres          
Password for user postgres: 
psql (12.1)
Type "help" for help.

postgres=# create database otus;
CREATE DATABASE
postgres=# \c
You are now connected to database "postgres" as user "postgres".
postgres=# \c otus 
You are now connected to database "otus" as user "postgres".
otus=# create table homework (id serial, word varchar);
CREATE TABLE
otus=# insert into homework (word) values ('test_repl1');
INSERT 0 1
otus=# select * from homework;
 id |    word    
----+------------
  1 | test_repl1
(1 row)
```
Проверим репликацию на хосте pg2:
```console
[root@pg2 ~]# psql -h 192.168.11.102 -p 6543  -U postgres
Password for user postgres: 
psql (12.1)
Type "help" for help.

postgres=# \c otus 
You are now connected to database "otus" as user "postgres".
otus=# select * from homework;
 id |    word    
----+------------
  1 | test_repl1
(1 row)

otus=#  select pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)

```
Запускаем switchover:
```console
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml switchover --master pg1 --candidate pg2 
When should the switchover take place (e.g. 2020-01-11T09:09 )  [now]: 
Current cluster topology
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.101 | Leader | running |  1 |         0 |
|   otus  |  pg2   | 192.168.11.102 |        | running |  1 |         0 |
|   otus  |  pg3   | 192.168.11.103 |        | running |  1 |         0 |
+---------+--------+----------------+--------+---------+----+-----------+
Are you sure you want to switchover cluster otus, demoting current master pg1? [y/N]: y
2020-01-11 08:09:52.11219 Successfully switched over to "pg2"
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.101 |        | stopped |    |   unknown |
|   otus  |  pg2   | 192.168.11.102 | Leader | running |  1 |           |
|   otus  |  pg3   | 192.168.11.103 |        | running |  1 |         0 |
+---------+--------+----------------+--------+---------+----+-----------+
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml list
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.101 |        | running |  2 |           |
|   otus  |  pg2   | 192.168.11.102 | Leader | running |  2 |         0 |
|   otus  |  pg3   | 192.168.11.103 |        | running |  2 |           |
+---------+--------+----------------+--------+---------+----+-----------+

```
Для проверки failover остановим patroni.service на текущем лидере pg2, проверим статус кластера и вернем узел в кластер:
```console
[root@pg2 ~]# systemctl stop patroni.service 
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml list
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.101 |        | running |  3 |         0 |
|   otus  |  pg3   | 192.168.11.103 | Leader | running |  3 |         0 |
+---------+--------+----------------+--------+---------+----+-----------+
[root@pg2 ~]# systemctl start patroni.service 
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml list
+---------+--------+----------------+--------+---------+----+-----------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB |
+---------+--------+----------------+--------+---------+----+-----------+
|   otus  |  pg1   | 192.168.11.101 |        | running |  3 |         0 |
|   otus  |  pg2   | 192.168.11.102 |        | running |  3 |         0 |
|   otus  |  pg3   | 192.168.11.103 | Leader | running |  3 |         0 |
+---------+--------+----------------+--------+---------+----+-----------+
```
Как видим после failover новым лидером стал pg3 и после старта patroni.service на pg2 в кластере все три узла.

Изменим параметр temp_buffers не требующий перезапуска:
```console
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml edit-config
--- 
+++ 
@@ -3,6 +3,7 @@
 postgresql:
   parameters:
     wal_keep_segments: 100
+    temp_buffers: 16MB
   use_pg_rewind: true
   use_slots: true
 retry_timeout: 10

Apply these changes? [y/N]: y
Configuration changed
```
В journalctl -u patroni.service видим запись:
```console
Jan 11 08:30:24 pg2 patroni[29170]: 2020-01-11 08:30:24,178 INFO: Changed temp_buffers from 1024 to 16MB
Jan 11 08:30:24 pg2 patroni[29170]: 2020-01-11 08:30:24,179 INFO: PostgreSQL configuration items changed, reloading configuration.
Jan 11 08:30:24 pg2 patroni[29170]: server signaled
```

Изменим параметр shared_buffers требующий перезапуска:
```console
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml edit-config
--- 
+++ 
@@ -4,6 +4,7 @@
   parameters:
     temp_buffers: 16MB
     wal_keep_segments: 100
+    shared_buffers: 256MB
   use_pg_rewind: true
   use_slots: true
 retry_timeout: 10

Apply these changes? [y/N]: y
Configuration changed
```
В journalctl -u patroni.service при этом:
```console
Jan 11 08:35:44 pg2 patroni[29170]: 2020-01-11 08:35:44,175 INFO: Changed shared_buffers from 16384 to 256MB (restart required)
```

Чтобы изменения применились на всех узлах, перезапускаем кластер:
```console
[root@pg2 ~]# patronictl -c /opt/app/patroni/etc/postgresql.yml restart otus
When should the restart take place (e.g. 2020-01-11T09:48)  [now]: 
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
| Cluster | Member |      Host      |  Role  |  State  | TL | Lag in MB | Pending restart |
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
|   otus  |  pg1   | 192.168.11.101 |        | running |  3 |         0 |        *        |
|   otus  |  pg2   | 192.168.11.102 |        | running |  3 |         0 |        *        |
|   otus  |  pg3   | 192.168.11.103 | Leader | running |  3 |         0 |        *        |
+---------+--------+----------------+--------+---------+----+-----------+-----------------+
Are you sure you want to restart members pg1, pg2, pg3? [y/N]: y
Restart if the PostgreSQL version is less than provided (e.g. 9.5.2)  []: 
Success: restart on member pg1
Success: restart on member pg2
Success: restart on member pg3

```
Соответственно параметр shared_buffers применился на pg1 и pg3:
```console
[root@pg3 ~]# psql -h 192.168.11.101 -p 6543 -U postgres
Password for user postgres: 
psql (12.1)
Type "help" for help.

postgres=# show shared_buffers ;
 shared_buffers 
----------------
 256MB
(1 row)

postgres=# \q
[root@pg3 ~]# psql -h 192.168.11.103 -p 6543 -U postgres
Password for user postgres: 
psql (12.1)
Type "help" for help.

postgres=# show shared_buffers ;
 shared_buffers 
----------------
 256MB
(1 row)
```
