# собственная сборка ядра

su -

yum install wget

mkdir kernel_sources

cd kernel_sources

wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.63.tar.xz

tar -xvf linux-4.19.63.tar.xz

cd linux-4.19.63

cp /boot/config* .config

yum install gcc bison flex bc elfutils-libelf-devel openssl-devel perl

make oldconfig

make

make install

make modules_install

