#!/bin/sh

curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.7.0-linux-x86_64.tar.gz
tar xzvf metricbeat-8.7.0-linux-x86_64.tar.gz
sudo mv metricbeat-8.7.0-linux-x86_64 /etc/metricbeat
sudo rm /etc/metricbeat/metricbeat.yml

sudo tee /etc/systemd/system/metricbeat.service > /dev/null <<EOF
[Unit]
Description=metricbeat
After=network-online.target
[Service]
User=$USER
WorkingDirectory=/etc/metricbeat
ExecStart=/etc/metricbeat/metricbeat -e
RestartSec=10
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable metricbeat
sudo systemctl start metricbeat
