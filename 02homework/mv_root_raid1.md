vagrant up
vagrant ssh
sudo su
lsblk
fdisk /dev/sdb
mdadm -C /dev/md0 -l 1 -n 2 missing /dev/sdb1
mdadm -D /dev/md0
lsblk
mkfs.xfs /dev/md0
mount /dev/md0 /mnt/
df -Th
rsync -aAx / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /mnt
for i in /proc/ /sys/ /dev/ /run/; do mount --bind $i /mnt/$i; done
chroot /mnt/
blkid
vi /etc/fstab (replace uid)
cat /etc/fstab 
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
cat /etc/mdadm/mdadm.conf
dracut --mdadmconf --fstab --add=mdraid --filesystems "xfs ext4 ext3 tmpfs devpts sysfs proc" --add-drivers=raid1 --force /boot/initramfs-$(uname -r).img $(uname -r) -M
vi /etc/default/grub (add GRUB_CMDLINE_LINUX="... rd.auto rd.auto=1" , add GRUB_PRELOAD_MODULES="mdraid1x")
cat /etc/default/grub 
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-install /dev/sdb
exit
reboot
vagrant ssh
sudo su
cat /proc/mdstat
lsblk
df -hT
sfdisk -d /dev/sdb | sfdisk /dev/sda
lsblk
mdadm /dev/md0 -a /dev/sda1
cat /proc/mdstat
mdadm -D /dev/md0
grub2-install /dev/sda
lsblk
reboot
vagrant ssh
lsblk
df -Th
cat /proc/mdstat
