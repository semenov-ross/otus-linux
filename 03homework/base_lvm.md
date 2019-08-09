# Выполнение основного задания
vagrant ssh  

## Уменьшаем том под / до 8G

### Доставляем xfsdump
sudo su
yum -y install xfsdump
### Создаём временный том
pvcreate /dev/sdb
vgcreate VGroot /dev/sdb
lvcreate -n LVroot -l +100%FREE /dev/VGroot
mkfs.xfs /dev/VGroot/LVroot
mount /dev/VGroot/LVroot /mnt/
### Копируем все данные с / в /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
### Сымитируем текущий root -> сделаем в него chroot и обновим grub
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
vi /boot/grub2/grub.cfg # replace rd.lvm.lv=VolGroup00/LogVol00 -> rd.lvm.lv=VGroot/LVroot
exit
reboot
vagrant ssh
sudo su
### Удаляем LV размером в 40G
lvremove /dev/VolGroup00/LogVol00
### Создаём размером 8G и монтируем в mnt
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt/
### Копируем данные из временного тома
xfsdump -J - /dev/VGroot/LVroot | xfsrestore -J - /mnt
### Перконфигурируем grub
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done

## Выделяем том под /var
### На дисках sdc, sdd делаем зеркало и перносим туда /var
pvcreate /dev/sdc /dev/sdd
vgcreate VGvar /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n LVvar VGvar

### Создаем ФС и перемещаем туда /var
mkfs.ext4 /dev/VGvar/LVvar
mount /dev/VGvar/LVvar /mnt
cp -aR /var/* /mnt/
### backup old /var
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
### Монтируем новый var в каталог /var:
umount /mnt
mount /dev/VGvar/LVvar /var
### Вносим в fstab монтирование /var
echo "`blkid | grep LVvar: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
exit
reboot

vagrant ssh
sudo su

### Удаляем временную VG
lvremove /dev/VGroot/LVroot
vgremove /dev/VGroot
pvremove /dev/sdb

## Выделяем том под /home
lvcreate -n LVhome -L 2G /dev/VolGroup00
mkfs.ext4 /dev/VolGroup00/LVhome
### Переносим
mount /dev/VolGroup00/LVhome /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt/
mount /dev/VolGroup00/LVhome /home/
### вносим в fstab
echo "`blkid | grep LVhome | awk '{print $2}'` /home ext4 defaults 0 0" >> /etc/fstab

### Сгенерируем файлы в /home/
touch /home/file{1..25}
### Снимаем снапшот
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LVhome
# Удаляем часть
rm -f /home/file{12..22}
# Восстанавливаем со снапшота
umount /home/
lvconvert --merge /dev/VolGroup00/home_snap
mount /home/
