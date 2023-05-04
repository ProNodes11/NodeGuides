#!/bin/bash

read -r -p "Enter node moniker: " NODE_MONIKER

echo -e "\033[0;31m Server preparing\033[0m"
CHAIN_ID="nolus-rila"
BINARY_VERSION_TAG="v0.2.2-store-fix"
PORT=30

rm -rf nolus-core
git clone https://github.com/Nolus-Protocol/nolus-core.git
cd nolus-core
git checkout $BINARY_VERSION_TAG
make install
nolusd version

echo -e "\033[0;31m Editing configs\033[0m"

nolusd config keyring-backend test
nolusd config chain-id $CHAIN_ID
nolusd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://snapshots-testnet.stake-town.com/nolus/genesis.json > $HOME/.nolus/config/genesis.json
curl -s https://snapshots-testnet.stake-town.com/nolus/addrbook.json > $HOME/.nolus/config/addrbook.json

sed -i 's|^pruning *=.*|pruning = "nothing"|g' $HOME/.nolus/config/app.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.nolus/config/config.toml
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.nolus/config/config.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025unls"|g' $HOME/.nolus/config/app.toml

sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):$PORT_PPROF_LADDR\"/" $HOME/.nolus/config/config.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:266${PORT}\"%laddr = \"tcp://0.0.0.0:${PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${PORT}660\"%" $HOME/.nolus/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${PORT}17\"%; s%^address = \":8080\"%address = \":${PORT}80\"%; s%^address = \"0.0.0.0:${PORT}90\"%address = \"0.0.0.0:${PORT}90\"%; s%^address = \"0.0.0.0:${PORT}91\"%address = \"0.0.0.0:${PORT}91\"%" $HOME/.nolus/config/app.toml
sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:${PORT}657\"%" $HOME/.nolus/config/client.toml

echo -e "\033[0;33m Install Cosmovisor\033[0m"
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

echo -e "\033[0;33m Configuring Cosmovisor\033[0m"
mkdir -p ~/.nolus/cosmovisor/genesis/bin
mkdir -p ~/.nolus/cosmovisor/upgrades

cp ~/go/bin/nolus ~/.nolus/cosmovisor/genesis/bin

echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/nolus.service  > /dev/null <<EOF
[Unit]
Description=Nolus node
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor start
Restart=always
RestartSec=10
LimitNOFILE=10000
Environment="DAEMON_NAME=nolus"
Environment="DAEMON_HOME=$HOME/.nolus"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
StandardOutput=append:/var/log/node-nolus
StandardError=append:/var/log/node-nolus

[Install]
WantedBy=multi-user.target
EOF

nolusd tendermint unsafe-reset-all --home $HOME/.nolus --keep-addr-book

URL="https://snapshots-testnet.stake-town.com/nolus/nolus-rila_latest.tar.lz4"
curl $URL | lz4 -dc - | tar -xf - -C $HOME/.nolus

echo -e "\033[0;31m Starting node\033[0m"
sudo systemctl daemon-reload
sudo systemctl enable nolus
sudo systemctl start nolus

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Nolus-node
  hosts: ['$(wget -qO- eth0.me):$(echo $PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Nolus"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-nolus
    fields:
      host: $HOSTNAME
      name: nolus
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

systemctl daemon-reload
systemctl enable nolus
systemctl restart nolus

echo -e "\033[0;33m Check services\033[0m"
if [[ `service heartbeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Heartbeat Successful\033[0m"
else
  echo -e "\033[0;31m Update Heartbeat failed\033[0m"
fi

if [[ `service filebeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Filebeat Successful\033[0m"
else
  echo -e "\033[0;31m Update Filebeat failed\033[0m"
fi

if [[ `service nolus status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
