## PostgreSQL

При запуске vagrant up по средством Vagrant Ansible Provisioner создаются 3 хоста master, slave и backup. 
Конфиг postgresql.conf хоста master:
```console
listen_addresses = '*'
max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = posix

wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB
max_wal_senders = 3

log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%a.log'
log_truncate_on_rotation = on
log_rotation_age = 1d
log_rotation_size = 0
log_line_prefix = '%m [%p] '
log_timezone = 'UTC'

datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
```
Конфиг pg_hba.conf хоста master:
```console
local   all             all                                             trust
host    all             all                     127.0.0.1/32            trust
host    all             all                     ::1/128                 trust
local   replication     all                                             trust
host    replication     all                     127.0.0.1/32            trust
host    replication     all                     ::1/128                 trust
host    replication     repluser                192.168.11.102/32       trust
host    replication     barman_streaming        192.168.11.103/32       md5
host    all             barman                  192.168.11.103/32       md5
host    all             all                     192.168.11.0/24         md5
```
Репликация и резервное копирования хоста master настроено с использованием слотов:
```console
otus=# select slot_name,slot_type,active from pg_replication_slots;
  slot_name   | slot_type | active 
--------------+-----------+--------
 standby_slot | physical  | t
 barman_slot  | physical  | t
(2 rows)

otus=# select usename,application_name,client_addr,state from pg_stat_replication;
     usename      |  application_name  |  client_addr   |   state   
------------------+--------------------+----------------+-----------
 repluser         | walreceiver        | 192.168.11.102 | streaming
 barman_streaming | barman_receive_wal | 192.168.11.103 | streaming
(2 rows)
```
Конфиг recovery.conf хоста slave:
```console
standby_mode = on
primary_conninfo = 'host=192.168.11.101 port=5432 user=repluser password=12345'
primary_slot_name = 'standby_slot'
trigger_file = '/tmp/postgresql.trigger'
```
При добавлении на хосте master записи в таблицу homework, проверяем результат репликации на хосте slave:
```console
postgres=# \c otus
You are now connected to database "otus" as user "postgres"

otus=# insert into homework (word) values ('test_repl1');
INSERT 0 1

[root@slave ~]# su - postgres
-bash-4.2$ psql 
psql (11.6)
Type "help" for help.

postgres=# \c otus 
You are now connected to database "otus" as user "postgres".
otus=# select * from homework;
 id |    word    
----+------------
  1 | test_repl1
(1 row)
```
Проверяем статус восстановления хоста slave:
```console
otus=# select pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)
```
Резервное копирование настроено на хосте backup по сценарию Backup via streaming protocol. 

Конфиг barman:
```console
[master-streaming]
description = "Master PostgreSQL server"
conninfo = host=192.168.11.101 user=barman dbname=postgres
streaming_conninfo = host=192.168.11.101 user=barman_streaming
backup_method = postgres
streaming_archiver = on
slot_name = barman_slot
create_slot = auto
path_prefix = "/usr/pgsql-11/bin"
```
Статус репликации:
```console
-bash-4.2$ barman replication-status master-streaming 
Status of streaming clients for server 'master-streaming':
  Current LSN on master: 0/60001A8
  Number of streaming clients: 2

  1. Async standby
     Application name: walreceiver
     Sync stage      : 5/5 Hot standby (max)
     Communication   : TCP/IP
     IP Address      : 192.168.11.102 / Port: 38740 / Host: -
     User name       : repluser
     Current state   : streaming (async)
     Replication slot: standby_slot
     WAL sender PID  : 7186
     Started at      : 2020-01-06 09:20:35.314341+00:00
     Sent LSN   : 0/60001A8 (diff: 0 B)
     Write LSN  : 0/60001A8 (diff: 0 B)
     Flush LSN  : 0/60001A8 (diff: 0 B)
     Replay LSN : 0/60001A8 (diff: 0 B)

  2. Async WAL streamer
     Application name: barman_receive_wal
     Sync stage      : 3/3 Remote write
     Communication   : TCP/IP
     IP Address      : 192.168.11.103 / Port: 38694 / Host: -
     User name       : barman_streaming
     Current state   : streaming (async)
     Replication slot: barman_slot
     WAL sender PID  : 7278
     Started at      : 2020-01-06 09:23:01.740372+00:00
     Sent LSN   : 0/60001A8 (diff: 0 B)
     Write LSN  : 0/60001A8 (diff: 0 B)
     Flush LSN  : 0/6000000 (diff: -424 B)
```
Так как активность записи на хосте master близка к нулю, инициируем переключение сегмента при помощи switch-wal:
```console
-bash-4.2$ barman switch-wal --archive master-streaming 
The WAL file 000000010000000000000003 has been closed on server 'master-streaming'
Waiting for the WAL file 000000010000000000000003 from server 'master-streaming' (max: 30 seconds)
Processing xlog segments from streaming for master-streaming
        000000010000000000000003
```
После этого проверяем статус резервируемого сервера:
```console
-bash-4.2$ barman check master-streaming                
Server master-streaming:
        PostgreSQL: OK
        is_superuser: OK
        PostgreSQL streaming: OK
        wal_level: OK
        replication slot: OK
        directories: OK
        retention policy settings: OK
        backup maximum age: OK (no last_backup_maximum_age provided)
        compression settings: OK
        failed backups: OK (there are 0 failed backups)
        minimum redundancy requirements: OK (have 0 backups, expected at least 0)
        pg_basebackup: OK
        pg_basebackup compatible: OK
        pg_basebackup supports tablespaces mapping: OK
        systemid coherence: OK (no system Id stored on disk)
        pg_receivexlog: OK
        pg_receivexlog compatible: OK
        receive-wal running: OK
        archiver errors: OK

```
Cоздаём резервную копию:
```console
-bash-4.2$ barman backup master-streaming --wait
Starting backup using postgres method for server master-streaming in /var/lib/barman/master-streaming/base/20200106T094435
Backup start at LSN: 0/4000140 (000000010000000000000004, 00000140)
Starting backup copy via pg_basebackup for 20200106T094435
Copy done (time: less than one second)
Finalising the backup.
This is the first backup for server master-streaming
WAL segments preceding the current backup have been found:
        000000010000000000000003 from server master-streaming has been removed
Backup size: 30.1 MiB
Backup end at LSN: 0/6000000 (000000010000000000000005, 00000000)
Backup completed (start time: 2020-01-06 09:44:35.544043, elapsed time: less than one second)
Waiting for the WAL file 000000010000000000000005 from server 'master-streaming'
Processing xlog segments from streaming for master-streaming
        000000010000000000000004
Processing xlog segments from streaming for master-streaming
        000000010000000000000005
```
И проверяем:
```console
-bash-4.2$ barman list-backup master-streaming 
master-streaming 20200106T094435 - Mon Jan  6 09:44:36 2020 - Size: 46.1 MiB - WAL Size: 0 B

-bash-4.2$ barman check master-streaming 
Server master-streaming:
        PostgreSQL: OK
        is_superuser: OK
        PostgreSQL streaming: OK
        wal_level: OK
        replication slot: OK
        directories: OK
        retention policy settings: OK
        backup maximum age: OK (no last_backup_maximum_age provided)
        compression settings: OK
        failed backups: OK (there are 0 failed backups)
        minimum redundancy requirements: OK (have 1 backups, expected at least 0)
        pg_basebackup: OK
        pg_basebackup compatible: OK
        pg_basebackup supports tablespaces mapping: OK
        systemid coherence: OK
        pg_receivexlog: OK
        pg_receivexlog compatible: OK
        receive-wal running: OK
        archiver errors: OK
```
