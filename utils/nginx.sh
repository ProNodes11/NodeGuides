#!/bin/bash
read -r -p "Enter node moniker: " PORT
read -r -p "Enter node moniker: " CHAIN

# Установка Nginx
apt-get update
apt-get install -y nginx

# Установка сертификатов
cp cert.pem /etc/nginx/cert.pem
cp private.key /etc/nginx/private.key

# Создание конфигурационного файла
cat > /etc/nginx/sites-enabled/default  << EOF
server {
    listen 443 ssl;
    server_name $CHAIN-rpc.stakeme.io;
    ssl_certificate /etc/nginx/cert.pem;
    ssl_certificate_key /etc/nginx/private.key;

    location / {
        proxy_pass http://localhost:${PORT}657;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl;
    server_name $CHAIN-api.stakeme.io;
    ssl_certificate /etc/nginx/cert.pem;
    ssl_certificate_key /etc/nginx/private.key;

    location / {
        proxy_pass http://localhost:${PORT}17;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Перезапуск Nginx
service nginx restart
