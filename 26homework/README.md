## Web сервера.  

При запуске vagrant up при помощи сценария ansible [provisioning/playbook.yml](provisioning/playbook.yml) создаётся 
виртуальная машина wwww, на которой установлен сервер nginx, в конфигурацию которого добавлено:

```console
location / {
            if ($cookie_checkbot != "true") {
                return 302 $scheme://$http_host/setcookie;
            }
        }

        location /setcookie {
            add_header Set-Cookie "checkbot=true";
            return 302 $scheme://$http_host/;
        }
```
Порт 80 гостевой машины проброшен на 8081. 
```console
==> www: Forwarding ports...
    www: 80 (guest) => 8081 (host) (adapter 1)
```
В результате обращения к серверу, при отсутствии куки checkbot, 
происходит редирект на /setcookie, добавляется кука и клиент отправляется на запрашиваемый ресурс

```console
curl -v -L 127.0.0.1:8081

   Trying 127.0.0.1:8081...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 8081 (#0)
> GET / HTTP/1.1
> Host: 127.0.0.1:8081
> User-Agent: curl/7.66.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 302 Moved Temporarily
< Server: nginx/1.16.1
< Date: Mon, 02 Dec 2019 11:23:28 GMT
< Content-Type: text/html
< Content-Length: 145
< Connection: keep-alive
< Location: http://127.0.0.1:8081/setcookie
< 
* Ignoring the response-body
* Connection #0 to host 127.0.0.1 left intact
* Issue another request to this URL: 'http://127.0.0.1:8081/setcookie'
* Found bundle for host 127.0.0.1: 0x55bb2d51e400 [serially]
* Can not multiplex, even if we wanted to!
* Re-using existing connection! (#0) with host 127.0.0.1
* Connected to 127.0.0.1 (127.0.0.1) port 8081 (#0)
> GET /setcookie HTTP/1.1
> Host: 127.0.0.1:8081
> User-Agent: curl/7.66.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 302 Moved Temporarily
< Server: nginx/1.16.1
< Date: Mon, 02 Dec 2019 11:23:28 GMT
< Content-Type: text/html
< Content-Length: 145
< Connection: keep-alive
< Location: http://127.0.0.1:8081/
* Added cookie checkbot="true" for domain 127.0.0.1, path /, expire 0
< Set-Cookie: checkbot=true
< 
* Ignoring the response-body
* Connection #0 to host 127.0.0.1 left intact
* Issue another request to this URL: 'http://127.0.0.1:8081/'
* Found bundle for host 127.0.0.1: 0x55bb2d51e400 [serially]
* Can not multiplex, even if we wanted to!
* Re-using existing connection! (#0) with host 127.0.0.1
* Connected to 127.0.0.1 (127.0.0.1) port 8081 (#0)
> GET / HTTP/1.1
> Host: 127.0.0.1:8081
> User-Agent: curl/7.66.0
> Accept: */*
> Cookie: checkbot=true
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: nginx/1.16.1
< Date: Mon, 02 Dec 2019 11:23:28 GMT
< Content-Type: text/html
< Content-Length: 4833
< Last-Modified: Fri, 16 May 2014 15:12:48 GMT
< Connection: keep-alive
< ETag: "53762af0-12e1"
< Accept-Ranges: bytes
....
* Connection #0 to host 127.0.0.1 left intact
```
