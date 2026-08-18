upstream app_upstream {
    server 127.0.0.1:${app_port};
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location /healthz {
        proxy_pass http://app_upstream/healthz;
    }

    location /readyz {
        proxy_pass http://app_upstream/readyz;
    }

    location / {
        proxy_pass http://app_upstream;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
