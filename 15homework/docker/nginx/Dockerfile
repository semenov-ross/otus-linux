FROM alpine:3.10

MAINTAINER semenovross <semenov.ross@gmail.com>

RUN	apk update && \
	apk upgrade && \
	apk add --update nginx && \
	rm -rf /var/cache/apk/*

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

VOLUME ["/var/log/nginx", "/www"]

EXPOSE 80 443

ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
