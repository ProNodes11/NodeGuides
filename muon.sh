#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

mkdir muon && cd muon
curl -o docker-compose.yml https://raw.githubusercontent.com/muon-protocol/muon-node-js/testnet/docker-compose-pull.yml
docker compose up -d
docker cp muon-node:/usr/src/muon-node-js/.env ./backup.env
cd ..

echo -e "\033[0;33m Updating configs\033[0m"

echo -e "\033[0;33m Update Heartbeat config\033[0m"
echo "- type: http
  hosts: ['$(wget -qO- eth0.me):8000/status']
  ipv4: true
  mode: any
  name: Muon-node
  timeout: 1s
  wait: 1s
  tags: ["Muon"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Check services\033[0m"
if [[ `service heartbeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Heartbeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Heartbeat failed\033[0m"
fi


echo -e "\033[0;33m Script ended\033[0m"
