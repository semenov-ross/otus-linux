### Сборка образов nginx и php-fpm

* [Dockerfile](docker/nginx/Dockerfile) - Dockerfile образа nginx
* [Dockerfile](docker/php/Dockerfile) - Dockerfile образа php-fpm

Сборка образа nginx на основе alpine:

```console
    cd /vagrant/docker/nginx
    docker build -t nginx .
```

Сборка образа php-fpm на основе alpine:

```console
    cd /vagrant/docker/php
    docker build -t php-fpm .
```
Каталоги docker/log и docker/www используются как постоянные хранилища для контейнеров.


### Загрузка образов в dockerhub

Вывести список локальных образов:
```console
    docker images
```
Назначить теги локальным образам:
```console
    docker tag 1ea0bc6a95ee semenovross/nginx
    docker tag dfe545bae4f9 semenovross/php-fpm
```
Загрузить образы в dockerhub:
```console
    docker login --username=semenovross
    docker push semenovross/nginx
    docker push semenovross/php-fpm
```
Cсылка на репозиторий - https://hub.docker.com/u/semenovross


При запуске vagrant up при выполнении провижининга [docker-compose.yml](docker/docker-compose.yml)
 c использованием образов на Docker Hub запускаются контейнеры 

Посмотреть phpinfo() можно по адресу http://192.168.11.101/



### Ответы на вопросы

#### Определите разницу между контейнером и образом:

Образ это набор слоёв, доступных только для чтения.  
Контейнер это изолированное пространство процессов с добавленным сверху слоем, доступным для записи.  

#### Можно ли в контейнере собрать ядро?

Да, можно.
