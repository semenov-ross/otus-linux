## Сетевые пакеты. VLAN'ы. LACP.  

#### Схема стенда  

![network](https://github.com/semenov-ross/otus-linux/blob/master/24homework/img/network23-54017-c98457.png)

Между centralRouter и inetRouter созданы 2 линка и объединины с помощью team-интерфейса team0 в режиме loadbalance:

```console
[root@centralRouter ~]# teamdctl team0 state
setup:
  runner: loadbalance
ports:
  eth1
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
  eth2
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
```
#### Проверка работы c отключением линка

```console
[root@centralRouter ~]# ip link set dev eth2 down

[root@centralRouter ~]# teamdctl team0 state
setup:
  runner: loadbalance
ports:
  eth1
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
  eth2
    link watches:
      link summary: down
      instance[link_watch_0]:
        name: ethtool
        link: down
        down count: 1

[root@centralRouter ~]# ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=61 time=50.2 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=61 time=50.9 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=61 time=50.9 ms

[root@centralRouter ~]# tracepath -n 8.8.8.8
 1?: [LOCALHOST]                                         pmtu 1500
 1:  192.168.255.1                                         1.240ms 
 1:  192.168.255.1                                         0.555ms 
^C

```

#### testClient1 <-> testServer1 testClient2 <-> testServer2 изолированы с помощью vlan100 и vlan101

```console
[vagrant@testClient1 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-eth1.100 
VLAN=yes
TYPE=Vlan
PHYSDEV=eth1
VLAN_ID=100
BOOTPROTO=none
IPADDR=10.10.10.1
PREFIX=24
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eth1.100
DEVICE=eth1.100
ONBOOT=yes

[vagrant@testServer2 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-eth1.101 
VLAN=yes
TYPE=Vlan
PHYSDEV=eth1
VLAN_ID=101
BOOTPROTO=none
IPADDR=10.10.10.254
PREFIX=24
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=eth1.101
DEVICE=eth1.101
ONBOOT=yes

```
#### Проверка доступности в тестовой сети:

```console
[vagrant@testClient1 ~]$ ping 10.10.10.254 -c 3
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.512 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.511 ms
64 bytes from 10.10.10.254: icmp_seq=3 ttl=64 time=0.452 ms

--- 10.10.10.254 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 0.452/0.491/0.512/0.037 ms
[vagrant@testClient1 ~]$ tracepath -n 10.10.10.254
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.10.254                                          0.702ms reached
 1:  10.10.10.254                                          0.492ms reached
     Resume: pmtu 1500 hops 1 back 1

[vagrant@testServer2 ~]$ ping 10.10.10.1 -c 3
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.266 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.302 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.641 ms

--- 10.10.10.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.266/0.403/0.641/0.168 ms
[vagrant@testServer2 ~]$ tracepath -n 10.10.10.1
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.10.1                                            0.598ms reached
 1:  10.10.10.1                                            0.510ms reached
     Resume: pmtu 1500 hops 1 back 1
```

#### Работа интернета с test хостов реализована посредством функционала network namespaces(netns)

Созданы два netns  
```console
[root@officeRouter ~]# ip netns 
VRF101 (id: 1)
VRF100 (id: 0)
```
На officeRouter созданы vlan интерфейсы с тегами 100 и 101 в VRF100 и VRF101 с адресом 10.10.10.2. 
Между netns и основным хостом создан veth линк 172.29.100.1-172.29.100.2 и veth линк 172.29.101.1-172.29.101.2 для маршуртизации трафика:

```console
[root@officeRouter ~]# ip netns exec VRF100 ip -4 a
5: eth2.100@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netnsid 0
    inet 10.10.10.2/24 scope global eth2.100
       valid_lft forever preferred_lft forever
7: veth100@if8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netnsid 0
    inet 172.29.100.2/30 scope global veth100
       valid_lft forever preferred_lft forever

[root@officeRouter ~]# ip netns exec VRF101 ip -4 a
6: eth2.101@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netnsid 0
    inet 10.10.10.2/24 scope global eth2.101
       valid_lft forever preferred_lft forever
9: veth101@if10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netnsid 0
    inet 172.29.101.2/30 scope global veth101
       valid_lft forever preferred_lft forever
```

Трансляция сети 10.10.10.0/24 в сеть 10.10.100(101):
```console
[root@officeRouter ~]# ip netns exec VRF100 iptables -nL -t nat
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
NETMAP     all  --  0.0.0.0/0            10.10.100.0/24      10.10.10.0/24

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
NETMAP     all  --  10.10.10.0/24        0.0.0.0/0           10.10.100.0/24

[root@officeRouter ~]# ip netns exec VRF101 iptables -nL -t nat
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
NETMAP     all  --  0.0.0.0/0            10.10.101.0/24      10.10.10.0/24

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
NETMAP     all  --  10.10.10.0/24        0.0.0.0/0           10.10.101.0/24
```
Маршрут по умолчанию в VRF100 и VRF101 через officeRouter 10.10.10.2:

```console
[vagrant@testClient1 ~]$ ip r
default via 10.10.10.2 dev eth1.100 
default via 10.0.2.2 dev eth0 proto dhcp metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
10.10.10.0/24 dev eth1.100 proto kernel scope link src 10.10.10.1 metric 400

[vagrant@testServer2 ~]$ ip r
default via 10.10.10.2 dev eth1.101 
default via 10.0.2.2 dev eth0 proto dhcp metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101 
10.10.10.0/24 dev eth1.101 proto kernel scope link src 10.10.10.254 metric 400
```
Получаем доступ для test хостов в интернет:
```console
[vagrant@testClient1 ~]$ ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=55 time=51.1 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=55 time=51.3 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=55 time=52.1 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 51.135/51.543/52.102/0.408 ms

[vagrant@testClient1 ~]$ tracepath -n 8.8.8.8
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.10.2                                            0.471ms 
 1:  10.10.10.2                                            0.382ms 
 2:  172.29.100.1                                          0.631ms 
 3:  192.168.255.5                                         0.998ms 
 4:  192.168.255.1                                         1.054ms 
^C

[vagrant@testServer2 ~]$ ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=55 time=51.1 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=55 time=51.9 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=55 time=51.9 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 51.120/51.651/51.931/0.419 ms

[vagrant@testServer2 ~]$ tracepath -n 8.8.8.8
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.10.2                                            1.015ms 
 1:  10.10.10.2                                            0.890ms 
 2:  172.29.101.1                                          0.597ms 
 3:  192.168.255.5                                         1.131ms 
 4:  192.168.255.1                                         1.517ms 
^C

```