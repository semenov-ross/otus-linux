## Динамический веб контент

При запуске vagrant up посредством Vagrant Ansible Provisioner создаётся виртульный хост с выбранным 
сценарием: nginx + java(tomcat) + go + ruby. 

Порты тестовых приложений пробошены через nginx:

```console
[root@web ~]# cat /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

        location /tomcat/ {
            proxy_pass http://127.0.0.1:8080/;
            proxy_redirect off;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /go/ {
            proxy_pass http://127.0.0.1:8090/;
            proxy_redirect off;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /ruby/ {
            rewrite /ruby/(.*) /$1 break;
            include uwsgi_params;
            uwsgi_pass 127.0.0.1:3031;
        }

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
```

Соответственно доступ к проектам:

  * [java (tomcat)](http://192.168.11.101/tomcat/sample/)  

  * [go](http://192.168.11.101/go/)  

  * [ruby](http://192.168.11.101/ruby/)  


