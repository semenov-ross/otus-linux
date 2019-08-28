## Управление пакетами. Дистрибьюция софта

  * Vagrantfile собирает систему и устанавливает необходимые пакеты

  * proc-analyze.spec - файл spec для сборки скрипта в RPM

  * Создаём структуру каталогов для сборки пакета:  
    mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}  

  * Копирум файл spec в соответствующую директорию:  
    cp proc-analyze.spec ~/rpmbuild/SPECS/  

  * Собираем RPM:  
    rpmbuild -ba ~/rpmbuild/SPECS/proc-analyze.spec  

  * Проверяем что пакет создался:
    ls -l rpmbuild/RPMS/noarch/  

  * Создаём свое репозиторий:
    mkdir localrepo  
    cp rpmbuild/RPMS/noarch/proc-analyze-0-1.el7.noarch.rpm localrepo/  
    createrepo localrepo/  

    cat >> /etc/yum.repos.d/ross.repo << EOF  
    [ross]  
    name=ross-nix  
    baseurl=file:///home/vagrant/localrepo  
    gpgcheck=0  
    enabled=1  
    EOF  

    yum repolist  

  * Устанвливаем пакет:
    sudo yum install proc-analyze -y  

  * Проверям работу:
    pars_proc_psax.sh
