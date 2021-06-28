FROM nginx:alpine AS builder

RUN set -ex; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        perl-dev \
        libedit-dev \
        mercurial \
        bash \
        alpine-sdk \
        findutils

RUN set -exo pipefail; \
    cd /tmp; \
    git clone https://github.com/google/ngx_brotli.git; \
    git clone https://github.com/arut/nginx-dav-ext-module.git; \
    git clone https://github.com/aperezdc/ngx-fancyindex.git; \
    git clone https://github.com/openresty/headers-more-nginx-module.git; \
    wget "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
        -O - | tar -xzf -

# Reuse same cli arguments as the nginx:alpine image used to build
RUN set -euxo pipefail; \
    CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p'); \
    cd /tmp/ngx_brotli; \
    git submodule update --init; \
    cd /tmp/nginx-$NGINX_VERSION; \
    /bin/sh -c "./configure $CONFARGS --with-compat --add-dynamic-module=/tmp/ngx_brotli --add-dynamic-module=/tmp/nginx-dav-ext-module --add-dynamic-module=/tmp/ngx-fancyindex --add-dynamic-module=/tmp/headers-more-nginx-module"; \
    make modules


FROM nginx:alpine

LABEL maintainer="jinlife <glucose1e@tom.com>"

COPY --from=builder \
    /tmp/nginx-${NGINX_VERSION}/objs/*_module.so \
    /usr/lib/nginx/modules/

# Download certbot
RUN apk -U upgrade \
	&& apk add --update --no-cache ca-certificates apache2-utils certbot certbot-nginx python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev openssl \
	&& pip3 install pip --upgrade \
	&& pip3 install certbot-dns-cloudflare \
	&& mkdir -p /etc/letsencrypt \
	&& mkdir -p /media

ARG MKCERT_VERSION="1.4.3"
# Download mkcert to generate selfsigned cert, for SSL 443 usage. Won't run unless define DOMAIN and no EMAIL.
RUN wget -O /usr/local/bin/mkcert https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64
RUN chmod +x /usr/local/bin/mkcert

COPY webdav.conf /etc/nginx/conf.d/default.conf
# COPY webdav.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

VOLUME /media

WORKDIR /media

ENV DOMAIN= \
    EMAIL= \
    TOKEN_KEY= \
    USERNAME=jinlife \
    PASSWORD= \
    LOCATION=/media

EXPOSE 80 443

STOPSIGNAL SIGTERM

ENTRYPOINT ["/bin/entrypoint.sh"]
