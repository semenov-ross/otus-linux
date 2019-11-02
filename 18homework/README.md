### Архитектура сетей
При запуске vagrant up создаются 5 хостов:
```console
Current machine states:

inetRouter                running (virtualbox)
centralRouter             running (virtualbox)
centralServer             running (virtualbox)
office1Router             running (virtualbox)
office1Server             running (virtualbox)
office2Router             running (virtualbox)
office2Server             running (virtualbox)
```

## Схема стенда:
```console

[office1Server] eth1<=192.168.2.66/26--- office1-test-server-net ----192.168.2.65/26=>eth3 [office1Router] eth1<=192.168.255.6/30-----+
																      |
																      |
																      |			  192.168.255.5/30
[centralServer] eth1<=192.168.0.2/28--- dir-net ---------------------192.168.0.1/28=>eth2 [centralRouter] eth1<=192.168.255.2/30------+--- router-net --- 192.168.255.1/30=>eth1 [inetRouter] eth0 WAN uplink (nat)
																      |			  192.168.255.9/30
																      |
																      |
[office2Server] eth1<=192.168.1.130/26--- office2-test-server-net ---192.168.1.129/26=>eth3 [office2Router] eth1<=192.168.255.10/30---+

```

Для организации связи офисов и центра на хосте inetRouter добавлены адреса на интерфейс eth1:
```console
    ip address add 192.168.255.5/30 dev eth1
    ip address add 192.168.255.9/30 dev eth1
```
Для сетей офисов и центра прописаны маршруты:
```console
    ip route add 192.168.0.0/24 via 192.168.255.2 dev eth1
    ip route add 192.168.2.0/24 via 192.168.255.6 dev eth1
    ip route add 192.168.1.0/24 via 192.168.255.10 dev eth1
```
Для хоста office1Router добавлен интерфейс для сети router-net 192.168.255.6/30. Для хоста office2Router так же для сети router-net 
добавлен интерфейс 192.168.255.10/30. Маршрут по умолчанию настроен через хост inetRouter.

Для office1Router
```console
    ip route del default
    ip route add default via 192.168.255.5 dev eth1
```

Для office2Router
```console
    ip route del default
    ip route add default via 192.168.255.9 dev eth1
```
Связь centralServer с office1Server:
```console
    [root@centralServer ~]# tracepath -n 192.168.2.66
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.0.1                                           1.786ms 
 1:  192.168.0.1                                           0.470ms 
 2:  192.168.255.1                                         0.636ms 
 3:  192.168.255.6                                         1.347ms 
 4:  192.168.2.66                                          2.476ms reached
     Resume: pmtu 1500 hops 4 back 4
```
Связь centralServer с office2Server:
```console
    [root@centralServer ~]# tracepath -n 192.168.1.130
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.0.1                                           1.329ms 
 1:  192.168.0.1                                           1.118ms 
 2:  192.168.255.1                                         1.686ms 
 3:  192.168.255.10                                        1.265ms 
 4:  192.168.1.130                                         2.060ms reached
     Resume: pmtu 1500 hops 4 back 4
```
Доступ в интернет с centralServer:
```console
    [root@centralServer ~]# ping -c 5 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=59 time=51.7 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=59 time=51.7 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=59 time=51.9 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=59 time=52.1 ms
64 bytes from 8.8.8.8: icmp_seq=5 ttl=59 time=51.9 ms

--- 8.8.8.8 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4017ms
rtt min/avg/max/mdev = 51.741/51.904/52.128/0.286 ms
```
Из вывода tracepath видно, что маршрут идёт через inetRouter(192.168.255.1):
```console
    [root@centralServer ~]# tracepath -n 8.8.8.8
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.0.1                                           1.525ms 
 1:  192.168.0.1                                           0.430ms 
 2:  192.168.255.1                                         0.650ms 
 3:  no reply
```

## Ответы на вопросы ДЗ

Свободные подсети:  

192.158.0.16/28  
192.168.0.48/28  
192.168.0.128/25  

Сеть central  
  - 192.168.0.0/28 - directors: всего 16 адресов, доступно для использования 14, broadcast 192.168.0.15  
  - 192.168.0.32/28 - office hardware: всего 16 адресов, доступно для использования 14, broadcast 192.168.0.47  
  - 192.168.0.64/26 - wifi: всего 64 адреса, доступно для использования 62, broadcast 192.168.0.127  

Сеть office1  
  - 192.168.2.0/26 - dev: всего 64 адреса, доступно для использования 62, broadcast 192.168.2.63  
  - 192.168.2.64/26 - test servers: всего 64 адреса, доступно для использования 62, broadcast 192.168.2.127  
  - 192.168.2.128/26 - managers: всего 64 адреса, доступно для использования 62, broadcast 192.168.2.191  
  - 192.168.2.192/26 - office hardware: всего 64 адреса, доступно для использования 62, broadcast 192.168.2.255  

Сеть office2  
  - 192.168.1.0/25 - dev: всего 128 адресов, доступно для использования 126, broadcast 192.168.1.127  
  - 192.168.1.128/26 - test servers: всего 64 адреса, доступно для использования 62, broadcast 192.168.1.191  
  - 192.168.1.192/26 - office hardware: всего 64 адреса, доступно для использования 62, broadcast 192.168.1.255  

