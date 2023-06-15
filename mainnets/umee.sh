#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

BABYLON_PORT=31
CHAIN_ID=bbn-test1

read -p "Enter moniker for node: " MONIKER

echo -e "\033[0;33m Install node\033[0m"
git clone https://github.com/babylonchain/babylon.git babylon
cd babylon
git checkout v0.5.0
make install
echo -e "\033[0;33m Configuring node\033[0m"
babylond init $MONIKER --chain-id $CHAIN_ID
curl -s https://snapshots.polkachu.com/testnet-genesis/babylon/genesis.json > $HOME/.babylond/config/genesis.json
babylond config chain-id $CHAIN_ID
babylond config keyring-backend test
babylond config node tcp://localhost:31657

echo -e "\033[0;33m Install Cosmovisor\033[0m"
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

echo -e "\033[0;33m Configuring Cosmovisor\033[0m"
mkdir -p ~/.babylond/cosmovisor/genesis/bin
mkdir -p ~/.babylond/cosmovisor/upgrades

cp ~/go/bin/babylond ~/.babylond/cosmovisor/genesis/bin


echo -e "\033[0;33m Creating service\033[0m"
sudo tee /etc/systemd/system/babylond.service  > /dev/null <<EOF
[Unit]
Description=Babylon node 
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor start
Restart=always
RestartSec=10
LimitNOFILE=10000
Environment="DAEMON_NAME=babylond"
Environment="DAEMON_HOME=$HOME/.babylond"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
StandardOutput=append:/var/log/node-babylon
StandardError=append:/var/log/node-babylon

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;33m Updating configs\033[0m"

echo -e "\033[0;33m Update node config\033[0m"
sed -i 's|^indexer *=.*|indexer = "null"|' ~/.babylond/config/config.toml
sed -i.bak -e 's|^pruning *=.*|pruning = "custom"|; s|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|; s|^pruning-keep-every *=.*|pruning-keep-every = "0"|; s|^pruning-interval *=.*|pruning-interval = "10"|' $HOME/.babylond/config/app.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${BABYLON_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${BABYLON_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${BABYLON_PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${BABYLON_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${BABYLON_PORT}660\"%" $HOME/.babylond/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${BABYLON_PORT}17\"%; s%^address = \":8080\"%address = \":${BABYLON_PORT}80\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${BABYLON_PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${BABYLON_PORT}91\"%" $HOME/.babylond/config/app.toml

echo -e "\033[0;33m Update Heartbeat config\033[0m"
echo "- type: http
  name: Babylon-node
  hosts: ['http://$(wget -qO- eth0.me):$(echo $BABYLON_PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Babylon"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-babylon
    fields:
      host: $HOSTNAME
      name: babylon
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

echo -e "\033[0;32m Starting node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable babylond
sudo -S systemctl start babylond

echo -e "\033[0;33m Check services\033[0m"
if [[ `service heartbeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Heartbeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Heartbeat failed\033[0m"
fi

if [[ `service filebeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Filebeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Filebeat failed\033[0m"
fi

if [[ `service babylond status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
