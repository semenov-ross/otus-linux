## Мосты, туннели и VPN.  

При запуске vagrant up создатся три хоста:

```console
server                    running (virtualbox)
clientTap                 running (virtualbox)
clientTun                 running (virtualbox)
```
На хосте server запущено три тунеля openvpn в режиме tap, tun и RAS:

```console
[root@server ~]# systemctl -t service | grep vpn
  openvpn-server@server-ras.service                     loaded active running OpenVPN service for server/ras
  openvpn-server@server-tap.service                     loaded active running OpenVPN service for server/tap
  openvpn-server@server-tun.service                     loaded active running OpenVPN service for server/tun
```

#### Хост server и clientTap связаны тунелем в режиме tap, который связывает сети, расположенные за дополнительно настроенным интерфейсом 
br0 
```console
[root@server ~]# cat /etc/sysconfig/network-scripts/ifcfg-br0 
STP=no
TYPE=Bridge
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=192.168.20.10
PREFIX=24
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV4_DNS_PRIORITY=100
IPV6INIT=no
NAME=br0
DEVICE=br0
ONBOOT=yes

[vagrant@clientTap ~]$ cat /etc/sysconfig/network-scripts/ifcfg-br0 
STP=no
TYPE=Bridge
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=192.168.20.11
PREFIX=24
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV4_DNS_PRIORITY=100
IPV6INIT=no
NAME=br0
DEVICE=br0
ONBOOT=yes

[root@server ~]# ip link | grep tap
5: tap0: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master br0 state UNKNOWN mode DEFAULT group default qlen 100
```
Интерфейсы tap0 добавлены в мост br0:

```console
[root@server ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.22c2221aad8e       no              tap0

[root@clientTap ~]# brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.e224fc497444       no              tap0
```

Доступность с хоста server:

```console
[root@server ~]# ping 192.168.20.11 -c 3
PING 192.168.20.11 (192.168.20.11) 56(84) bytes of data.
64 bytes from 192.168.20.11: icmp_seq=1 ttl=64 time=1.92 ms
64 bytes from 192.168.20.11: icmp_seq=2 ttl=64 time=1.00 ms
64 bytes from 192.168.20.11: icmp_seq=3 ttl=64 time=1.58 ms

--- 192.168.20.11 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 1.005/1.503/1.921/0.379 ms
```
Доступность с хоста clientTap:

```console
[vagrant@clientTap ~]$ping 192.168.20.10 -c 3
PING 192.168.20.10 (192.168.20.10) 56(84) bytes of data.
64 bytes from 192.168.20.10: icmp_seq=1 ttl=64 time=0.775 ms
64 bytes from 192.168.20.10: icmp_seq=2 ttl=64 time=1.26 ms
64 bytes from 192.168.20.10: icmp_seq=3 ttl=64 time=1.36 ms

--- 192.168.20.10 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 0.775/1.132/1.362/0.259 ms
````
#### Результаты теста iperf3:

```console
[root@clientTap ~]# iperf3 -c 192.168.20.10 -t 40 -i 5
Connecting to host 192.168.20.10, port 5201
[  4] local 192.168.20.11 port 42676 connected to 192.168.20.10 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec   112 MBytes   188 Mbits/sec   22    210 KBytes       
[  4]   5.00-10.01  sec   113 MBytes   190 Mbits/sec  104    225 KBytes       
[  4]  10.01-15.01  sec   112 MBytes   189 Mbits/sec   18    296 KBytes       
[  4]  15.01-20.00  sec   112 MBytes   188 Mbits/sec   71    278 KBytes       
[  4]  20.00-25.00  sec   113 MBytes   190 Mbits/sec   24    341 KBytes       
[  4]  25.00-30.00  sec   113 MBytes   189 Mbits/sec   26    218 KBytes       
[  4]  30.00-35.00  sec   114 MBytes   191 Mbits/sec   13    258 KBytes       
[  4]  35.00-40.00  sec   113 MBytes   189 Mbits/sec   11    281 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   902 MBytes   189 Mbits/sec  289             sender
[  4]   0.00-40.00  sec   901 MBytes   189 Mbits/sec                  receiver

iperf Done.

[root@server ~]# iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 192.168.20.11, port 42674
[  5] local 192.168.20.10 port 5201 connected to 192.168.20.11 port 42676
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.01   sec  20.6 MBytes   172 Mbits/sec                  
[  5]   1.01-2.00   sec  22.1 MBytes   186 Mbits/sec                  
[  5]   2.00-3.00   sec  22.7 MBytes   191 Mbits/sec                  
[  5]   3.00-4.00   sec  22.8 MBytes   191 Mbits/sec                  
[  5]   4.00-5.01   sec  22.3 MBytes   186 Mbits/sec                  
[  5]   5.01-6.00   sec  21.9 MBytes   185 Mbits/sec                  
[  5]   6.00-7.00   sec  22.7 MBytes   190 Mbits/sec                  
[  5]   7.00-8.01   sec  23.0 MBytes   191 Mbits/sec                  
[  5]   8.01-9.01   sec  22.5 MBytes   189 Mbits/sec                  
[  5]   9.01-10.00  sec  22.8 MBytes   192 Mbits/sec                  
[  5]  10.00-11.00  sec  22.4 MBytes   187 Mbits/sec                  
[  5]  11.00-12.00  sec  22.7 MBytes   190 Mbits/sec                  
[  5]  12.00-13.01  sec  22.3 MBytes   187 Mbits/sec                  
[  5]  13.01-14.00  sec  22.2 MBytes   188 Mbits/sec                  
[  5]  14.00-15.00  sec  22.6 MBytes   189 Mbits/sec                  
[  5]  15.00-16.01  sec  22.4 MBytes   188 Mbits/sec                  
[  5]  16.01-17.01  sec  22.2 MBytes   186 Mbits/sec                  
[  5]  17.01-18.00  sec  22.2 MBytes   187 Mbits/sec                  
[  5]  18.00-19.01  sec  22.7 MBytes   189 Mbits/sec                  
[  5]  19.01-20.00  sec  22.5 MBytes   190 Mbits/sec                  
[  5]  20.00-21.00  sec  22.7 MBytes   190 Mbits/sec                  
[  5]  21.00-22.00  sec  22.8 MBytes   192 Mbits/sec                  
[  5]  22.00-23.01  sec  22.6 MBytes   188 Mbits/sec                  
[  5]  23.01-24.01  sec  22.7 MBytes   190 Mbits/sec                  
[  5]  24.01-25.01  sec  22.6 MBytes   190 Mbits/sec                  
[  5]  25.01-26.01  sec  22.6 MBytes   190 Mbits/sec                  
[  5]  26.01-27.00  sec  22.5 MBytes   190 Mbits/sec                  
[  5]  27.00-28.01  sec  22.8 MBytes   191 Mbits/sec                  
[  5]  28.01-29.00  sec  22.9 MBytes   193 Mbits/sec                  
[  5]  29.00-30.00  sec  22.2 MBytes   186 Mbits/sec                  
[  5]  30.00-31.01  sec  22.6 MBytes   189 Mbits/sec                  
[  5]  31.01-32.01  sec  22.9 MBytes   191 Mbits/sec                  
[  5]  32.01-33.00  sec  23.0 MBytes   194 Mbits/sec                  
[  5]  33.00-34.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  34.00-35.00  sec  22.7 MBytes   190 Mbits/sec                  
[  5]  35.00-36.00  sec  22.6 MBytes   190 Mbits/sec                  
[  5]  36.00-37.01  sec  22.7 MBytes   189 Mbits/sec                  
[  5]  37.01-38.00  sec  22.2 MBytes   188 Mbits/sec                  
[  5]  38.00-39.00  sec  22.5 MBytes   189 Mbits/sec                  
[  5]  39.00-40.00  sec  22.6 MBytes   190 Mbits/sec                  
[  5]  40.00-40.05  sec  1.14 MBytes   213 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.05  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.05  sec   901 MBytes   189 Mbits/sec                  receiver
```
#### Хост server и clientTun объединены тунелем в режиме tun, который связывает сети 192.168.20.0/24 и  192.168.30.0/24.  

Маршрут на хосте clientTun
```console
[root@clientTun ~]# ip r | grep tun0
10.10.0.1 dev tun0 proto kernel scope link src 10.10.0.2 
192.168.20.0/24 via 10.10.0.1 dev tun0
```
Маршрут с хоста server
```console
[root@server ~]# ip r | grep tun0
10.10.0.2 dev tun0 proto kernel scope link src 10.10.0.1 
192.168.30.0/24 via 10.10.0.2 dev tun0
```
#### Результаты теста iperf3:

```console
[root@clientTun ~]# iperf3 -c 10.10.0.1 -t 40 -i 5
Connecting to host 10.10.0.1, port 5201
[  4] local 10.10.0.2 port 59992 connected to 10.10.0.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  60.5 MBytes   101 Mbits/sec    0    647 KBytes       
[  4]   5.00-10.00  sec  93.6 MBytes   157 Mbits/sec   13    481 KBytes       
[  4]  10.00-15.01  sec  94.3 MBytes   158 Mbits/sec    0    597 KBytes       
[  4]  15.01-20.00  sec  94.2 MBytes   158 Mbits/sec    1    580 KBytes       
[  4]  20.00-25.01  sec  87.3 MBytes   146 Mbits/sec    0    663 KBytes       
[  4]  25.01-30.01  sec  89.4 MBytes   150 Mbits/sec    2    615 KBytes       
[  4]  30.01-35.01  sec  90.2 MBytes   151 Mbits/sec    1    540 KBytes       
[  4]  35.01-40.00  sec  92.4 MBytes   155 Mbits/sec    0    630 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec   702 MBytes   147 Mbits/sec   17             sender
[  4]   0.00-40.00  sec   701 MBytes   147 Mbits/sec                  receiver

iperf Done.

[root@server ~]# iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.0.2, port 59990
[  5] local 10.10.0.1 port 5201 connected to 10.10.0.2 port 59992
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  7.37 MBytes  61.8 Mbits/sec                  
[  5]   1.00-2.00   sec  6.99 MBytes  58.7 Mbits/sec                  
[  5]   2.00-3.00   sec  8.48 MBytes  71.0 Mbits/sec                  
[  5]   3.00-4.01   sec  15.2 MBytes   127 Mbits/sec                  
[  5]   4.01-5.00   sec  20.2 MBytes   170 Mbits/sec                  
[  5]   5.00-6.00   sec  18.2 MBytes   154 Mbits/sec                  
[  5]   6.00-7.00   sec  19.3 MBytes   162 Mbits/sec                  
[  5]   7.00-8.00   sec  18.8 MBytes   158 Mbits/sec                  
[  5]   8.00-9.00   sec  19.1 MBytes   161 Mbits/sec                  
[  5]   9.00-10.00  sec  18.0 MBytes   150 Mbits/sec                  
[  5]  10.00-11.00  sec  19.1 MBytes   161 Mbits/sec                  
[  5]  11.00-12.00  sec  18.5 MBytes   155 Mbits/sec                  
[  5]  12.00-13.00  sec  19.1 MBytes   160 Mbits/sec                  
[  5]  13.00-14.00  sec  18.3 MBytes   154 Mbits/sec                  
[  5]  14.00-15.00  sec  19.1 MBytes   160 Mbits/sec                  
[  5]  15.00-16.00  sec  19.2 MBytes   162 Mbits/sec                  
[  5]  16.00-17.00  sec  18.3 MBytes   154 Mbits/sec                  
[  5]  17.00-18.01  sec  19.2 MBytes   160 Mbits/sec                  
[  5]  18.01-19.01  sec  18.0 MBytes   152 Mbits/sec                  
[  5]  19.01-20.00  sec  20.1 MBytes   170 Mbits/sec                  
[  5]  20.00-21.01  sec  15.5 MBytes   129 Mbits/sec                  
[  5]  21.01-22.01  sec  18.4 MBytes   155 Mbits/sec                  
[  5]  22.01-23.01  sec  18.3 MBytes   153 Mbits/sec                  
[  5]  23.01-24.00  sec  18.0 MBytes   152 Mbits/sec                  
[  5]  24.00-25.00  sec  16.5 MBytes   138 Mbits/sec                  
[  5]  25.00-26.01  sec  17.6 MBytes   147 Mbits/sec                  
[  5]  26.01-27.01  sec  17.4 MBytes   146 Mbits/sec                  
[  5]  27.01-28.00  sec  19.7 MBytes   167 Mbits/sec                  
[  5]  28.00-29.01  sec  16.9 MBytes   140 Mbits/sec                  
[  5]  29.01-30.00  sec  18.1 MBytes   153 Mbits/sec                  
[  5]  30.00-31.00  sec  19.1 MBytes   160 Mbits/sec                  
[  5]  31.00-32.01  sec  18.0 MBytes   150 Mbits/sec                  
[  5]  32.01-33.00  sec  16.2 MBytes   136 Mbits/sec                  
[  5]  33.00-34.00  sec  18.4 MBytes   154 Mbits/sec                  
[  5]  34.00-35.00  sec  18.3 MBytes   154 Mbits/sec                  
[  5]  35.00-36.00  sec  19.0 MBytes   160 Mbits/sec                  
[  5]  36.00-37.00  sec  17.3 MBytes   145 Mbits/sec                  
[  5]  37.00-38.01  sec  17.3 MBytes   145 Mbits/sec                  
[  5]  38.01-39.01  sec  19.2 MBytes   161 Mbits/sec                  
[  5]  39.01-40.00  sec  20.2 MBytes   170 Mbits/sec                  
[  5]  40.00-40.05  sec   912 KBytes   141 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.05  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.05  sec   701 MBytes   147 Mbits/sec                  receiver
```
### Для подключения к OpenVPN RAS с локальной машины необходимо использовать сертификаты и файлы конфигурации [OpenVPN RAS config](provisioning/clientLocal)

Подключение с локальной машины на виртуалку:

```console
client]# openvpn --config client.conf 
Sun Dec  1 23:58:48 2019 OpenVPN 2.4.8 x86_64-redhat-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Nov  1 2019
Sun Dec  1 23:58:48 2019 library versions: OpenSSL 1.1.1d FIPS  10 Sep 2019, LZO 2.08
Sun Dec  1 23:58:48 2019 TCP/UDP: Preserving recently used remote address: [AF_INET]127.0.0.1:1195
Sun Dec  1 23:58:48 2019 Socket Buffers: R=[131072->131072] S=[16384->16384]
Sun Dec  1 23:58:48 2019 Attempting to establish TCP connection with [AF_INET]127.0.0.1:1195 [nonblock]
Sun Dec  1 23:58:48 2019 TCP connection established with [AF_INET]127.0.0.1:1195
Sun Dec  1 23:58:48 2019 TCP_CLIENT link local: (not bound)
Sun Dec  1 23:58:48 2019 TCP_CLIENT link remote: [AF_INET]127.0.0.1:1195
Sun Dec  1 23:58:48 2019 TLS: Initial packet from [AF_INET]127.0.0.1:1195, sid=d3510f32 a3568f35
Sun Dec  1 23:58:48 2019 VERIFY OK: depth=1, CN=rasvpn
Sun Dec  1 23:58:48 2019 VERIFY KU OK
Sun Dec  1 23:58:48 2019 Validating certificate extended key usage
Sun Dec  1 23:58:48 2019 ++ Certificate has EKU (str) TLS Web Server Authentication, expects TLS Web Server Authentication
Sun Dec  1 23:58:48 2019 VERIFY EKU OK
Sun Dec  1 23:58:48 2019 VERIFY OK: depth=0, CN=rasvpn
Sun Dec  1 23:58:48 2019 Control Channel: TLSv1.2, cipher TLSv1.2 ECDHE-RSA-AES256-GCM-SHA384, 2048 bit RSA
Sun Dec  1 23:58:48 2019 [rasvpn] Peer Connection Initiated with [AF_INET]127.0.0.1:1195
Sun Dec  1 23:58:49 2019 SENT CONTROL [rasvpn]: 'PUSH_REQUEST' (status=1)
Sun Dec  1 23:58:49 2019 PUSH: Received control message: 'PUSH_REPLY,route 192.168.20.0 255.255.255.0,dhcp-option DNS 8.8.8.8,route 192.168.80.1,topology net30,ping 10,ping-restart 120,ifconfig 192.168.80.6 192.168.80.5,peer-id 0,cipher AES-256-GCM'
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: timers and/or timeouts modified
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: --ifconfig/up options modified
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: route options modified
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: --ip-win32 and/or --dhcp-option options modified
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: peer-id set
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: adjusting link_mtu to 1627
Sun Dec  1 23:58:49 2019 OPTIONS IMPORT: data channel crypto options modified
Sun Dec  1 23:58:49 2019 Data Channel: using negotiated cipher 'AES-256-GCM'
Sun Dec  1 23:58:49 2019 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Sun Dec  1 23:58:49 2019 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Sun Dec  1 23:58:49 2019 ROUTE_GATEWAY 178.34.128.66
Sun Dec  1 23:58:49 2019 TUN/TAP device tun0 opened
Sun Dec  1 23:58:49 2019 TUN/TAP TX queue length set to 100
Sun Dec  1 23:58:49 2019 /sbin/ip link set dev tun0 up mtu 1500
Sun Dec  1 23:58:49 2019 /sbin/ip addr add dev tun0 local 192.168.80.6 peer 192.168.80.5
Sun Dec  1 23:58:52 2019 /sbin/ip route add 192.168.20.0/24 via 192.168.80.5
Sun Dec  1 23:58:52 2019 /sbin/ip route add 192.168.80.1/32 via 192.168.80.5
Sun Dec  1 23:58:52 2019 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
Sun Dec  1 23:58:52 2019 Initialization Sequence Completed
```
