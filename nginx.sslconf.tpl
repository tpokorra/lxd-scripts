## Start CONTAINERURL ##
server {
    listen 80;
    server_name CONTAINERURL;
    return 302 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name  CONTAINERURL;
 
    ssl_certificate /var/lib/certs/CERTURL.crt;
    ssl_certificate_key /var/lib/certs/CERTURL.key;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols  TLSv1.2 TLSv1.3;  # don't use SSLv3 ref: POODLE

    # Logjam https://weakdh.org/sysadmin.html
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_prefer_server_ciphers on;
    ssl_dhparam /var/lib/certs/dhparams.pem;

    access_log  /var/log/nginx/log/CONTAINERURL.access.log;
    error_log  /var/log/nginx/log/CONTAINERURL.error.log;
    root   /usr/share/nginx/html;
    index  index.html index.htm;

    client_max_body_size 30M;
 
    ## send request back to container ##
    location / {
     proxy_pass  http://CONTAINERIP:CONTAINERPORT/SUBDIR;
     proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
     proxy_redirect off;
     proxy_buffering off;
     proxy_set_header        Host            $host;
     proxy_set_header        X-Real-IP       $remote_addr;
     proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_set_header        X-Forwarded-Proto $scheme;
   }
}
## End CONTAINERURL ##
