При запуске vagrant up при помощи сценария ansible [mysql.yml](playbooks/mysql.yml) ролью [percona](roles/percona/tasks/main.yml) 
создаются два сервера, на которых устанавливается mysql Percona. Производится смена временного пароля пользователя root и создается файл [my.cnf](roles/percona/templates/root.cnf.j2) 
для входа в mysql без ввода пароля,c добавлением опциий для mysqldump.

При помощи роли [master](roles/master/tasks/main.yml) восстанавливается из дампа база bet и создаётся пользователь repl для выполнения репликации.  

При помощи роли [slave](roles/slave/tasks/main.yml) настраивается и запускается репликация.  

Статус сервера master:
```console
mysql> show master status\G
*************************** 1. row ***************************
             File: mysql-bin.000002
         Position: 119461
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: b7ca7f53-180d-11ea-8dfa-5254008afee6:1-39
1 row in set (0.00 sec)
```
Состав таблиц базы bet:
```console
ysql> show tables;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)
```
Для проверки GTID репликации вставляем строку в таблицу bookmaker на сервере master:
```console
mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.01 sec)

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```
И проверяем статус сервера slave:
```console
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.101
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 119757
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 119970
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 119757
              Relay_Log_Space: 120177
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: b7ca7f53-180d-11ea-8dfa-5254008afee6
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: b7ca7f53-180d-11ea-8dfa-5254008afee6:1-40
            Executed_Gtid_Set: b7ca7f53-180d-11ea-8dfa-5254008afee6:1-40,
fa61316f-180d-11ea-8f64-5254008afee6:1
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.00 sec)
```
Видим, что таблицы bet.events_on_demand и bet.v_same_event исключены из репликации так, как это прописано в конфигурационном файле [05-binlog.cnf](roles/percona/files/slave/05-binlog.cnf). 

В результате репликации запись появилась на сервере slave:
```console
mysql> select * from bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```
Это так же отображено в binary логах сервера slave:
```console
[root@slave ~]# mysqlbinlog /var/lib/mysql/slave-relay-bin.000002 | grep INSERT | tail -1
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
```
