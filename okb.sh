#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

OKB_PORT=27
CHAIN_ID=okbchaintest-195

read -p "Enter moniker for node: " MONIKER

echo -e "\033[0;33m Install node\033[0m"
git clone https://github.com/okx/okbchain.git
cd okbchain
export GO111MODULE=on
make rocksdb
make testnet
echo -e "\033[0;33m Configuring node\033[0m"
okbchaind init $MONIKER --chain-id $CHAIN_ID
curl -S https://raw.githubusercontent.com/okx/okexchain-docs/okbchain-docs/resources/genesis-file/testnet/genesis.json > ~/.okbchaind/config/genesis.json
okbchaind config chain-id $CHAIN_ID
okbchaind config keyring-backend test
okbchaind config node tcp://localhost:27657

echo -e "\033[0;33m Install Cosmovisor\033[0m"
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

echo -e "\033[0;33m Configuring Cosmovisor\033[0m"
mkdir -p ~/.nibid/cosmovisor/genesis/bin
mkdir -p ~/.nibid/cosmovisor/upgrades

cp ~/go/bin/okbchaind ~/.okbchaind/cosmovisor/genesis/bin


echo -e "\033[0;33m Creating service\033[0m"
sudo tee /etc/systemd/system/okbchaind.service  > /dev/null <<EOF
[Unit]
Description=Okb node 
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor start
Restart=always
RestartSec=10
LimitNOFILE=10000
Environment="DAEMON_NAME=okbchaind"
Environment="DAEMON_HOME=$HOME/.okbchaind"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
StandardOutput=append:/var/log/node-okb
StandardError=append:/var/log/node-okb

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;33m Updating configs\033[0m"

echo -e "\033[0;33m Update node config\033[0m"
sed -i 's|^indexer *=.*|indexer = "null"|' ~/.okbchaind/config/config.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${OKB_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${OKB_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${OKB_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${OKB_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${OKB_PORT}660\"%" $HOME/.okbchaind/config/config.toml

echo -e "\033[0;33m Update Heartbeat config\033[0m"
echo "- type: http
  name: Okb-node
  hosts: ['$(wget -qO- eth0.me):$(echo $OKB_PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Okb"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-okb
    fields:
      host: $HOSTNAME
      name: okb
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

echo -e "\033[0;32m Starting node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable okbchaind
sudo -S systemctl start okbchaind

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

if [[ `service okbchaind status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
