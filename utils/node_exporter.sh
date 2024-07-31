#!/bin/bash

sudo useradd --system --shell /bin/false node_exporter
curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz \
  | sudo tar -zxvf - -C /usr/local/bin --strip-components=1 node_exporter-1.3.1.linux-amd64/node_exporter \
  && sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo tee /etc/systemd/system/node_exporter.service <<"EOF"
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
Group=node_exporter
EnvironmentFile=-/etc/sysconfig/node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:40140

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && \
sudo systemctl start node_exporter && \
sudo systemctl status node_exporter && \
sudo systemctl enable node_exporter
