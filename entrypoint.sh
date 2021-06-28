#!/bin/sh

# Write username and password to htpasswd
if [[ "x$USERNAME" != "x" && "x$PASSWORD" != "x" ]]
then
	htpasswd -bc /etc/nginx/htpasswd $USERNAME $PASSWORD
	echo "Username and Password Done."
fi

sed -i '1i\load_module /usr/lib/nginx/modules/ngx_http_dav_ext_module.so;' /etc/nginx/nginx.conf
head -n1 /etc/nginx/nginx.conf

# Get Let's Encrypted certificate from DNS-01 with cloudflare, not support free domain(freenom: tk, ml, ga, cf, gq)
if [[  "x$DOMAIN" != "x" &&  "x$EMAIL" != "x"  &&  "x$TOKEN_KEY" != "x"  ]]
then

# Generate certificate by certbot
cat > //etc/letsencrypt/cloudflare.ini << EOF
		dns_cloudflare_api_token = ${TOKEN_KEY}
EOF
chmod 600 /etc/letsencrypt/cloudflare.ini
certbot certonly --dns-cloudflare -m ${EMAIL} --agree-tos --non-interactive --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini -d ${DOMAIN} -d *.${DOMAIN}

# Renew for 1 of each month by cron job
echo "0 0 1 * * /usr/bin/certbot renew --quiet --deploy-hook \"service nginx reload\"" >> /etc/crontabs/root
echo "Certbot generate certificate for ${DOMAIN} success."

cat > /etc/nginx/conf.d/default.conf << EOF
server {
	listen 443 ssl;
	server_name $DOMAIN;
	client_max_body_size 0;
	proxy_max_temp_file_size 0;
	proxy_buffering off;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
	ssl_prefer_server_ciphers on;

	location / {
        root /media/;
		charset utf-8;
        dav_methods PUT DELETE MKCOL COPY MOVE;
		dav_ext_methods PROPFIND OPTIONS;
		create_full_put_path  on;
        dav_access user:rw group:rw all:r;
		autoindex     on;

        auth_basic "Restricted";
    	  auth_basic_user_file /etc/nginx/htpasswd;
		}
	}
EOF

elif [[  "x$DOMAIN" != "x"  ]]
then

# Generate selfsigned certificate
SERVER_ALIAS="`printf 'localhost,127.0.0.1,::1,%s' "$DOMAIN" | tr ',' ' '`"
/usr/local/bin/mkcert -install
/usr/local/bin/mkcert -cert-file /etc/nginx/selfsigned.crt -key-file /etc/nginx/selfsigned.key $SERVER_ALIAS

cat > /etc/nginx/conf.d/default.conf << EOF
server {
	listen 443 ssl;
	client_max_body_size 0;
	proxy_max_temp_file_size 0;
	proxy_buffering off;
	ssl_certificate /etc/nginx/selfsigned.crt;
	ssl_certificate_key /etc/nginx/selfsigned.key;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers HIGH:MEDIUM:!aNULL:!MD5:!SSLv3:!SSLv2:!TLSv1;

	location / {
        root /media/;
		charset utf-8;
        dav_methods PUT DELETE MKCOL COPY MOVE;
		dav_ext_methods PROPFIND OPTIONS;
		create_full_put_path  on;
        dav_access user:rw group:rw all:r;
		autoindex     on;

        auth_basic "Restricted";
    	  auth_basic_user_file /etc/nginx/htpasswd;
		}
	}
EOF

else

# DEFAULT 80 port without SSL, best network speed
cat > /etc/nginx/conf.d/default.conf << EOF
server {
    listen 80;
    client_max_body_size 0;
	proxy_max_temp_file_size 0;
	proxy_buffering off;

    location / {
        root /media/;
		charset utf-8;
        dav_methods PUT DELETE MKCOL COPY MOVE;
		dav_ext_methods PROPFIND OPTIONS;
		create_full_put_path  on;
        dav_access user:rw group:rw all:r;
		autoindex     on;

        auth_basic "Restricted";
    	  auth_basic_user_file /etc/nginx/htpasswd;
		}
	}
EOF

fi

# Defaults to caddyuser:caddyuser (99:99).
nginx -g "daemon off;"
