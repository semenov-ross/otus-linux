## Загрузка системы  

* Попасть в систему без пароля  

    Способ 1.  

    Попадаем в окно где мы можем изменить параметры загрузки  
    В строке, начинающейся с linux16 удаляем параметр console=...  
    Добавляем в конце строки rd.break вместо rhgb quiet  
    Нажимаем ctrl+x  
    Попадаем в emergency mode  
    После загрузки оболочки необходимо перемонтировать корневой раздел в режим RW:  
    mount -o remount,rw /sysroot  
    chroot /sysroot  
    passwd  
    touch /.autorelabel  
    exit  
    exit  

    Способ 2  

    Попадаем в окно где мы можем изменить параметры загрузки  
    В строке, начинающейся с linux16 удаляем параметр console=...  
    Меняем ro на rw  
    Добавляем в конце строки rd.break enforcing=0 вместо rhgb quiet  
    chroot /sysroot  
    passwd  
    restorecon /etc/shadow (вместо touch /.autorelabel так как указали enforcing=0)  
    exit  
    exit  


* Переименовываем VG и LV  

    vgrename VolGroup00 VGroot
    lvrename VGroot LogVol00 LVroot
    lvrename VGroot LogVol01 LVswap

Далее правим /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg.  
Везде заменяем старое название на новое.  

[typescript](typescript) - Процесс переименования vg и lv  

После загузки получим:  

     [root@lvm ~]# vgs
     VG     #PV #LV #SN Attr   VSize   VFree
     VGroot   1   2   0 wz--n- <38.97g    0
     [root@lvm ~]# lvs
     LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
     LVroot VGroot -wi-ao---- <37.47g 
     LVswap VGroot -wi-ao----   1.50g 

