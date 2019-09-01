## Управление пакетами. Дистрибьюция софта

  * Vagrantfile собирает систему, устанавливает необходимые пакеты, создаёт свой репозиторий yum

  * proc-analyze.spec - файл spec для сборки скрипта в RPM  

Создание docker образа  

    sudo su -l
    yum install docker -y
    systemctl start docker
    cd /vagrant
    docker pull centos
    docker build -t centos:a1 .

Статус команды запуска контейнера:  

    [root@otuslinux vagrant]# docker run -t -i centos:a1
    PID     TTY     STAT TIME    COMMAND
    1       ?       Ss+  00:00   /bin/bash/usr/bin/pars_proc_psax.sh

