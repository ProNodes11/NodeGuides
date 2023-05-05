#!/bin/bash

echo -e "\033[0;31m Downloading node\033[0m"
wget https://get.gear.rs/gear-nightly-linux-x86_64.tar.xz && \
tar xvf gear-nightly-linux-x86_64.tar.xz && \
rm gear-nightly-linux-x86_64.tar.xz
sudo cp gear /usr/bin
read -p "Enter Name for node: " NODE_NAME
echo 'export NODE_NAME='${NODE_NAME} >> $HOME/.bash_profile

echo -e "\033[0;31m Creating service for node\033[0m"
sudo tee /etc/systemd/system/gear.service  > /dev/null <<EOF
[Unit]
Description=Gear Node
After=network.target

[Service]

Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/usr/bin/gear --name "$NODE_NAME" --telemetry-url "ws://telemetry-backend-shard.gear-tech.io:32001/submit 0"
Restart=always
RestartSec=3
LimitNOFILE=10000
StandardOutput=append:/var/log/node-gear
StandardError=append:/var/log/node-gear

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;31m Starting node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable gear
sudo -S systemctl start gear

echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-gear
    fields:
      host: $HOSTNAME
      name: gear
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

systemctl daemon-reload
systemctl enable gear
systemctl restart gear

if [[ `service filebeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Filebeat Successful\033[0m"
else
  echo -e "\033[0;31m Update Filebeat failed\033[0m"
fi

if [[ `service gear status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
