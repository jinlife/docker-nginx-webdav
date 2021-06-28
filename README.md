# docker-cwebdav
This image runs an easily configurable WebDAV server with nginx, support plain, selfsigned or Let's Encrypt certificate.

* **Code repository:** https://github.com/jinlife/docker-nginx-webdav
* **Docker:** https://hub.docker.com/r/jinlife/docker-nginx-webdav
  
## Usage

### Basic WebDAV server

This example starts a WebDAV server on port 80. It can only be accessed with a single username and password. 

```
docker run --restart always -v /path/to/directory:/media \
    -e USERNAME=jinlife -e PASSWORD=123123 \
    --publish 80:80 -d jinlife/docker-nginx-webdav
```

#### Via Docker Compose:

```
version: '3'
services:
  webdav:
    image: jinlife/docker-nginx-webdav
    restart: always
    ports:
      - "80:80"
    environment:
      USERNAME: jinlife
      PASSWORD: 123123
    volumes:
      - /path/to/directory:/media

```
### Secure WebDAV with SSL

#### Self signed certificate
If you're happy with a self-signed certificate, specify `-e DOMAIN=youdomain.com,192.168.0.88,xxx` and the container will generate one cert and key for all domain or ip.

```
docker run --restart always -v /path/to/directory:/media \
    -e USERNAME=jinlife -e PASSWORD=123123 \
    -e DOMAIN=youdomain.com,192.168.0.88 --publish 443:443 -d jinlife/docker-nginx-webdav

```

#### Let's Encrypt certificate
If you want the caddy to auto generate Let's Encrypt certificate for you , then specify `-e DOMAIN=youdomain.com` with only one domain and specify `-e EMAIL=CloudflareAccountEmail.com` and `-e TOKEN_KEY=Cloudflare_TOKEN_KEY` to be used in acme.

This is only suitable for Cloudflare managed Domain and use DNS to generate the SSL。It will also succeed for non 443 HTTPS server.

```
docker run --restart always -v /path/to/directory:/media \
    -e USERNAME=jinlife -e PASSWORD=123123 \
    -e DOMAIN=youdomain.com -e EMAIL=youremail.com -e TOKEN_KEY=xxxxxxxxx --publish 443:443 -d docker-nginx-webdav

```

### Environment variables

All environment variables are optional. You probably want to at least specify `USERNAME` and `PASSWORD` otherwise nobody will be able to access your WebDAV server!

* **`DOMAIN`**: Comma-separated list of domains (eg, `example.com,www.example.com`). multiple domains are for self signed certificate and one domain is for Let's Encrypt certificate.
* **`EMAIL`**: EMAIL defined to generate Let's Encrypt certificate, if not defined, then docker will auto switch to self signed certificate.
* **`TOKEN_KEY`**: TOKEN_KEY defined to store the cloudflare TOKEN_KEY, not GLOBAL API KEY, The TOKEN_KEY generate with ZONE:ZONE:READ and ZONE:DNS:EDIT permission
* **`USERNAME`**: Authenticate with this username
* **`PASSWORD`**: Authenticate with this password
