## MySQL кластер

Стенд настраивался с использованием статьи [Docker Compose Setup for InnoDB Cluster](https://mysqlrelease.com/2018/03/docker-compose-setup-for-innodb-cluster/). 
Использованы последние актуальные версии mysql-server, mysql-shell и mysql-router на дату выполнения. 
Образ [mysql-shell](docker_mysql_cluster/mysql-shell) создан на основе образа centos:7 и размещён в [dockerhub](https://hub.docker.com/r/semenovross/mysql-shell).

При запуске vagrant up в результате провижининга, при помощи [docker-compose](docker_mysql_cluster/docker-compose.yml) на созданной ВМ запускаются три контейнера docker 
с сервером mysql, контейнер mysql-router и контейнер mysql-shell:

```console
root@inodbcl ~]# docker ps --format "table {{.ID}}:\t{{.Command}}\t{{.Names}}"
CONTAINER ID        COMMAND                  NAMES
e4c7ee8418b9:       "/run.sh mysqlrouter"    dockermysqlcluster_mysql-router_1
b4c9f9fb2ddc:       "/run.sh mysqlsh"        dockermysqlcluster_mysql-shell_1
8981fe1001fc:       "/entrypoint.sh my..."   dockermysqlcluster_mysql-server-2_1
272e5e90e398:       "/entrypoint.sh my..."   dockermysqlcluster_mysql-server-3_1
fe34d1c6c778:       "/entrypoint.sh my..."   dockermysqlcluster_mysql-server-1_1
```
Состояние кластера проверяем через mysql-shell:
```console
[root@inodbcl ~]# docker exec -it dockermysqlcluster_mysql-shell_1 mysqlsh
MySQL Shell 8.0.18

Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > shell.connect('root@mysql-server-1:3306', 'root')
Creating a session to 'root@mysql-server-1:3306'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 3234
Server version: 8.0.18 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
<ClassicSession:root@mysql-server-1:3306>
 MySQL  mysql-server-1:3306 ssl  JS > dba.getCluster().status()
{
    "clusterName": "OtusCluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "272e5e90e398:3306", 
        "ssl": "REQUIRED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "272e5e90e398:3306": {
                "address": "272e5e90e398:3306", 
                "mode": "R/W",
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }, 
            "8981fe1001fc:3306": {
                "address": "8981fe1001fc:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }, 
            "fe34d1c6c778:3306": {
                "address": "fe34d1c6c778:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "272e5e90e398:3306"
}
```
Выключим ноду mysql-server-3,находящуюся в режиме "mode": "R/W" и проверим работу кластера:
```console
[root@inodbcl ~]# docker stop dockermysqlcluster_mysql-server-3_1
dockermysqlcluster_mysql-server-3_1
[root@inodbcl ~]# docker exec -it dockermysqlcluster_mysql-shell_1 mysqlsh
MySQL Shell 8.0.18

Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > shell.connect('root@mysql-server-1:3306', 'root')
Creating a session to 'root@mysql-server-1:3306'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 4152
Server version: 8.0.18 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
<ClassicSession:root@mysql-server-1:3306>
 MySQL  mysql-server-1:3306 ssl  JS > dba.getCluster().status()
{
    "clusterName": "OtusCluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "8981fe1001fc:3306", 
        "ssl": "REQUIRED", 
        "status": "OK_NO_TOLERANCE", 
        "statusText": "Cluster is NOT tolerant to any failures. 1 member is not active", 
        "topology": {
            "272e5e90e398:3306": {
                "address": "272e5e90e398:3306", 
                "mode": "n/a", 
                "readReplicas": {}, 
                "role": "HA", 
                "shellConnectError": "MySQL Error 2005 (HY000): Unknown MySQL server host '272e5e90e398' (2)", 
                "status": "(MISSING)"
            }, 
            "8981fe1001fc:3306": {
                "address": "8981fe1001fc:3306", 
                "mode": "R/W", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }, 
            "fe34d1c6c778:3306": {
                "address": "fe34d1c6c778:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "8981fe1001fc:3306"
}
```
В "mode": "R/W" переключилась нода mysql-server-2.

Включаем ноду mysql-server-3 и смотрим статус кластера:
```console
[root@inodbcl ~]# docker start dockermysqlcluster_mysql-server-3_1             
dockermysqlcluster_mysql-server-3_1
[root@inodbcl ~]# docker exec -it dockermysqlcluster_mysql-shell_1 mysqlsh     
MySQL Shell 8.0.18

Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
Oracle is a registered trademark of Oracle Corporation and/or its affiliates.
Other names may be trademarks of their respective owners.

Type '\help' or '\?' for help; '\quit' to exit.
 MySQL  JS > shell.connect('root@mysql-server-1:3306', 'root')
Creating a session to 'root@mysql-server-1:3306'
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 4768
Server version: 8.0.18 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.
<ClassicSession:root@mysql-server-1:3306>
 MySQL  mysql-server-1:3306 ssl  JS > dba.getCluster().status()
{
    "clusterName": "OtusCluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "8981fe1001fc:3306", 
        "ssl": "REQUIRED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.", 
        "topology": {
            "272e5e90e398:3306": {
                "address": "272e5e90e398:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }, 
            "8981fe1001fc:3306": {
                "address": "8981fe1001fc:3306", 
                "mode": "R/W", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }, 
            "fe34d1c6c778:3306": {
                "address": "fe34d1c6c778:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "replicationLag": null, 
                "role": "HA", 
                "status": "ONLINE", 
                "version": "8.0.18"
            }
        }, 
        "topologyMode": "Single-Primary"
    }, 
    "groupInformationSourceMember": "8981fe1001fc:3306"
}
```
Подключаемся к кластеру с хоста через mysql-router:
```console
mysql -h 127.0.0.1 -P 6446 -uroot -proot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 305
Server version: 8.0.18 MySQL Community Server - GPL

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+-------------------------------+
| Database                      |
+-------------------------------+
| information_schema            |
| mysql                         |
| mysql_innodb_cluster_metadata |
| otus                          |
| performance_schema            |
| sys                           |
+-------------------------------+
6 rows in set (0.003 sec)

MySQL [(none)]>
```
