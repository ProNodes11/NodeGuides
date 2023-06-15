#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

NODE_PORT=51
CHAIN_ID=umee-1
VERISON_TAG="v0.5.1"

read -p "Enter moniker for node: " MONIKER

echo -e "\033[0;33m Install node\033[0m"
git clone https://github.com/umee-network/umee umee
cd umee
git checkout $VERISON_TAG
make install
echo -e "\033[0;33m Configuring node\033[0m"
umeed init $MONIKER --chain-id $CHAIN_ID
curl -s https://snapshots.polkachu.com/genesis/umee/genesis.json  > $HOME/.umee/config/genesis.json
umeed config chain-id $CHAIN_ID
umeed config node tcp://localhost:51657

echo -e "\033[0;33m Install Cosmovisor\033[0m"
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

echo -e "\033[0;33m Configuring Cosmovisor\033[0m"
mkdir -p ~/.umee/cosmovisor/genesis/bin
mkdir -p ~/.umee/cosmovisor/upgrades

cp ~/go/bin/umeed ~/.umee/cosmovisor/genesis/bin


echo -e "\033[0;33m Creating service\033[0m"
sudo tee /etc/systemd/system/umeed.service  > /dev/null <<EOF
[Unit]
Description=Umee node 
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor start
Restart=always
RestartSec=10
LimitNOFILE=10000
Environment="DAEMON_NAME=umeed"
Environment="DAEMON_HOME=$HOME/.umee"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
StandardOutput=append:/var/log/node-umee
StandardError=append:/var/log/node-umee

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;33m Updating configs\033[0m"

echo -e "\033[0;33m Update node config\033[0m"
sed -i.bak -e 's|^pruning *=.*|pruning = "custom"|; s|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|; s|^pruning-keep-every *=.*|pruning-keep-every = "2000"|; s|^pruning-interval *=.*|pruning-interval = "10"|' $HOME/.umee/config/app.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NODE_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${NODE_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NODE_PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NODE_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NODE_PORT}660\"%" $HOME/.umee/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${NODE_PORT}17\"%; s%^address = \":8080\"%address = \":${NODE_PORT}80\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NODE_PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NODE_PORT}91\"%" $HOME/.umee/config/app.toml
sed -i 's/snapshot-interval = 0/snapshot-interval = 2000/' $HOME/.umee/config/app.toml
sed -i 's/snapshot-keep-recent = 0/snapshot-keep-recent = 2/' $HOME/.umee/config/app.toml
echo -e "\033[0;33m Update Heartbeat config\033[0m"
echo "- type: http
  name: Umee-node
  hosts: ['http://$(wget -qO- eth0.me):$(echo $NODE_PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Umee"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-umee
    fields:
      host: $HOSTNAME
      name: umee
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
