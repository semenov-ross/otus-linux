## Файловые хранилища - NFS, SMB, FTP

При запуске vagrant up посредством Vagrant Ansible Provisioner создаются два хоста server и client 

На хосте server firewall запущен со следующими параметрами:

```console
[root@server ~]# firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: ssh dhcpv6-client nfs3 mountd rpc-bind
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules:
```

Список экспортируемых каталогов хоста server:
```console
[root@server ~]# exportfs -s
/mnt/nfs/dir1  192.168.11.102(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

Статистика nfs сервера, указывающая на использование 3 версии:
```console
[root@server ~]# nfsstat -l
nfs v3 server        total:       43 
------------- ------------- --------
nfs v3 server         null:        2 
nfs v3 server      getattr:       22 
nfs v3 server      setattr:        1 
nfs v3 server       lookup:        2 
nfs v3 server       access:        4 
nfs v3 server        write:        2 
nfs v3 server       create:        2 
nfs v3 server  readdirplus:        3 
nfs v3 server       fsstat:        2 
nfs v3 server       fsinfo:        2 
nfs v3 server     pathconf:        1
```

На хосте client в файле fstab прописано монтирование экспортируемого каталога:
```console
[root@client ~]# cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Sat Jun  1 17:13:31 2019
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=8ac075e3-1124-4bb6-bef7-a6811bf8b870 /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
192.168.11.101:/mnt/nfs/dir1 /mnt/nfs/dir1 nfs vers=3,udp,noexec,nosuid 0 0
```
На хосте client cмотрим список катологов сервера, опции монтирования nfs каталога и информацию о файловых системах:
```console
[root@client ~]# showmount -e 192.168.11.101
Export list for 192.168.11.101:
/mnt/nfs/dir1 192.168.11.102

[root@client ~]# grep nfs/dir1 /etc/mtab
192.168.11.101:/mnt/nfs/dir1 /mnt/nfs/dir1 nfs rw,nosuid,noexec,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.11.101,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.11.101 0 0

[root@client ~]# df -Th
Filesystem                   Type      Size  Used Avail Use% Mounted on
/dev/sda1                    xfs        40G  2.9G   38G   8% /
devtmpfs                     devtmpfs  236M     0  236M   0% /dev
tmpfs                        tmpfs     244M     0  244M   0% /dev/shm
tmpfs                        tmpfs     244M  4.5M  240M   2% /run
tmpfs                        tmpfs     244M     0  244M   0% /sys/fs/cgroup
tmpfs                        tmpfs      49M     0   49M   0% /run/user/1000
192.168.11.101:/mnt/nfs/dir1 nfs        40G  2.9G   38G   8% /mnt/nfs/dir1
```
Каталога nfs доступен для записи на хосте client:

```console
[root@client ~]# echo "Test_nfs" > /mnt/nfs/dir1/test
[root@client ~]# cat /mnt/nfs/dir1/test 
Test_nfs
[root@client ~]# ll /mnt/nfs/dir1/test 
-rw-r--r--. 1 nfsnobody nfsnobody 9 Jan 25 14:57 /mnt/nfs/dir1/test
```
