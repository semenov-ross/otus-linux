## Фильтрация трафика
При запуске vagrant up создаются 8 хостов:
```console
Current machine states:

inetRouter                running (virtualbox)
inetRouter2               running (virtualbox)
centralRouter             running (virtualbox)
centralServer             running (virtualbox)
office1Router             running (virtualbox)
office1Server             running (virtualbox)
office2Router             running (virtualbox)
office2Server             running (virtualbox)
```

### Схема стенда:
```console

[office1Server] eth1<=192.168.2.66/26--- office1-test-server-net ----192.168.2.65/26=>eth3 [office1Router] eth1<=192.168.255.6/30-----+
																      |
																      |
																      |			     192.168.255.5/30
[centralServer] eth1<=192.168.0.2/28--- dir-net ---------------------192.168.0.1/28=>eth2 [centralRouter] eth1<=192.168.255.2/30------+--- router-net ------ 192.168.255.1/30=>eth1 [inetRouter] eth0 WAN uplink (nat)
														192.168.254.2/30------|---+		     192.168.255.9/30
																      |   |
																      |   |
[office2Server] eth1<=192.168.1.130/26--- office2-test-server-net ---192.168.1.129/26=>eth3 [office2Router] eth1<=192.168.255.10/30---+   |
																	  |
																	  +---router-net --- 192.168.254.1/30=>eth1 [inetRouter2] eth0 WAN uplink (nat)

```

Доступ по ssh c centralRouter на inetrRouter организован через knock скрипт:
```console
[root@centralRouter ~]# ssh root@192.168.255.1
^C

[root@centralRouter ~]# /vagrant/knock.sh 192.168.255.1 8881 7777 9991

[root@centralRouter ~]# ssh root@192.168.255.1
root@192.168.255.1's password: 
Last login: Mon Nov  4 13:29:02 2019 from 192.168.255.2
[root@inetRouter ~]#
```

На хосте centralServer запущен nginx. 80й порт на inetRouter2 проброшен через порт 8080  
```console
[root@centralRouter ~]# curl -I 192.168.254.1:8080
HTTP/1.1 200 OK
Server: nginx/1.16.1
Date: Mon, 04 Nov 2019 13:40:39 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes
```
Доступ в интернет через хост inetRouter(192.168.255.1)
```console
[vagrant@centralServer ~]$ tracepath -n 8.8.8.8
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.0.1                                           1.252ms 
 1:  192.168.0.1                                           0.631ms 
 2:  192.168.255.1                                         1.801ms 
 3:  no reply
```
