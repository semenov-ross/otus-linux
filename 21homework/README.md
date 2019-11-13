## Статическая и динамическая маршрутизация

При запуске vagrant up при помощи сценария ansible [playbooks/ospf.yml](playbooks/ospf.yml) с использованием роли
[roles/zebra](roles/zebra) создатся три виртуальные машины R1, R2 и R3,
на которых устанавливается и настраивается OSPF на базе Quagga.  

#### Схема сети имеет вид:  

```console

                            10.40.0.0/24
	                         |
                                 |
                                 |
                                [R1]
                     10.10.0.1/30/\ 10.20.0.1/30
                                /  \
                               /    \
                              /      \
                             /        \
                            /          \
                           /            \
                          /              \
                         /                \
              net-r1-r2 /                  \ net-r1-r3
                       /                    \
                      /                      \
                     /                        \
                    /                          \
                   /                            \
                  /                              \
                 /                                \
                /                                  \
  10.10.0.2/30 /                                    \10.20.0.2/30
            [R2] 10.30.0.1/30 ------- 10.30.0.2/30 [R3]
             |               net-r2-r3               |
             |                                       |
             |                                       |
        10.50.0.0/24                            10.60.0.0/24


```
#### Асимметричный роутинг

На роутере R1 увеличена стоимость маршрута(ip ospf cost 20) в сторону роутера R2 и 
на роутере R2 увеличена стоимость маршрута(ip ospf cost 20) в сторону роутера R3.
В следствии этого маршрут с R1 в сторону R2 идет через R3(10.30.0.0/30 via 10.20.0.2 dev eth2).  

```console
[root@R1 ~]# ip r
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.0.0/30 dev eth1 proto kernel scope link src 10.10.0.1 metric 101 
10.20.0.0/30 dev eth2 proto kernel scope link src 10.20.0.1 metric 102 
10.30.0.0/30 via 10.20.0.2 dev eth2 proto zebra metric 20 
10.40.0.0/24 dev eth3 proto kernel scope link src 10.40.0.1 metric 103 
10.50.0.0/24 proto zebra metric 30 
        nexthop via 10.10.0.2 dev eth1 weight 1 
        nexthop via 10.20.0.2 dev eth2 weight 1 
10.60.0.0/24 via 10.20.0.2 dev eth2 proto zebra metric 20 
[root@R1 ~]# tracepath 10.30.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.20.0.2                                             0.642ms 
 1:  10.20.0.2                                             1.446ms 
 2:  10.30.0.1                                             0.848ms reached
     Resume: pmtu 1500 hops 2 back 1
```
А обратный маршрут с R2 на R1 идет через R1(10.20.0.0/30 via 10.10.0.1 dev eth1).  

```console
[root@R2 ~]# ip r
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.0.0/30 dev eth1 proto kernel scope link src 10.10.0.2 metric 101 
10.20.0.0/30 via 10.10.0.1 dev eth1 proto zebra metric 20 
10.30.0.0/30 dev eth2 proto kernel scope link src 10.30.0.1 metric 102 
10.40.0.0/24 via 10.10.0.1 dev eth1 proto zebra metric 20 
10.50.0.0/24 dev eth3 proto kernel scope link src 10.50.0.1 metric 103 
10.60.0.0/24 proto zebra metric 30 
        nexthop via 10.30.0.2 dev eth2 weight 1 
        nexthop via 10.10.0.1 dev eth1 weight 1 
[root@R2 ~]# tracepath 10.20.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.20.0.1                                             0.626ms reached
 1:  10.20.0.1                                             1.499ms reached
     Resume: pmtu 1500 hops 1 back 1
```
#### Симметричный роутинг с "дорогим" линком
Для того, чтобы создать симметричный роутинг с одним "дорогим" линком изменим стоимость маршрутов 
на роутере R2. Увеличим стоимость маршрута в сторону R1 и снизим в сторону R3:  

```console
[root@R2 ~]# vtysh 

Hello, this is Quagga (version 0.99.22.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

R2# configure terminal
R2(config)# interface eth1
R2(config-if)# ip ospf cost 20
R2(config-if)# interface eth2
R2(config-if)# ip ospf cost 10
R2(config-if)# exit

```
Получим маршрут с R2 на R1 через роутер R3(10.20.0.0/30 via 10.30.0.2 dev eth2) такой же, как и с R1 на R2:  

```console
[root@R2 ~]# ip r
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.0.0/30 dev eth1 proto kernel scope link src 10.10.0.2 metric 101 
10.20.0.0/30 via 10.30.0.2 dev eth2 proto zebra metric 20 
10.30.0.0/30 dev eth2 proto kernel scope link src 10.30.0.1 metric 102 
10.40.0.0/24 proto zebra metric 30 
        nexthop via 10.10.0.1 dev eth1 weight 1 
        nexthop via 10.30.0.2 dev eth2 weight 1 
10.50.0.0/24 dev eth3 proto kernel scope link src 10.50.0.1 metric 103 
10.60.0.0/24 via 10.30.0.2 dev eth2 proto zebra metric 20

[root@R2 ~]# tracepath 10.20.0.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.30.0.2                                             1.472ms 
 1:  10.30.0.2                                             0.740ms 
 2:  10.20.0.1                                             1.271ms reached
     Resume: pmtu 1500 hops 2 back 2
```
