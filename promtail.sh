#!/bin/bash
apt install unzip
if [ ! $NAME ]; then
read -p "Enter log name: " NAME
echo 'export NAME='\"${NAME}\" >> $HOME/.bash_profile
fi
if [ ! $JOB_NAME ]; then
read -p "Enter job name: " JOB_NAME
echo 'export JOB_NAME='\"${JOB_NAME}\" >> $HOME/.bash_profile
fi
curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep browser_download_url |  cut -d '"' -f 4 | grep promtail-linux-amd64.zip | wget -i -
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

touch /etc/promtail-local-config.yaml
cat << EOF >> /etc/promtail-local-config.yaml

server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /data/loki/positions.yaml

clients:
  - url: http://65.108.83.53:3100/loki/api/v1/push

scrape_configs:
- job_name: $NAME
  static_configs:
  - targets:
      - localhost
    labels:
      job: $JOB_NAME
      __path__: /var/log/$Name
EOF

sudo tee /etc/systemd/system/promtail.service<<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl start promtail.service
