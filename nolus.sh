#!/bin/bash

read -r -p "Enter node moniker: " NODE_MONIKER

echo -e "\033[0;31m Server preparing\033[0m"
CHAIN_ID="nolus-rila"
CHAIN_DENOM="unls"
BINARY_NAME="nolusd"
BINARY_VERSION_TAG="v0.2.2-store-fix"

echo -e "Node moniker:       $NODE_MONIKER"
echo -e "Chain id:           $CHAIN_ID"
echo -e "Chain demon:        $CHAIN_DENOM"
echo -e "Binary version tag: $BINARY_VERSION_TAG"

cd $HOME
rm -rf nolus-core
git clone https://github.com/Nolus-Protocol/nolus-core.git
cd nolus-core
git checkout $BINARY_VERSION_TAG
make install
nolusd version

nolusd config keyring-backend test
nolusd config chain-id $CHAIN_ID
nolusd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://snapshots-testnet.stake-town.com/nolus/genesis.json > $HOME/.nolus/config/genesis.json
curl -s https://snapshots-testnet.stake-town.com/nolus/addrbook.json > $HOME/.nolus/config/addrbook.json

CONFIG_TOML=$HOME/.nolus/config/config.toml
PEERS="5c236704215735ea722a3ca742a5161c2e871ec6@nolus-testnet.nodejumper.io:29656,5c2a752c9b1952dbed075c56c600c3a79b58c395@195.3.220.135:27016,c6e7b095d965209c8d15086c2a173627fb9b29e1@161.97.169.22:26656,e0aac09f3de68abf583b0e3994228ee8bd19d1eb@168.119.124.130:45659,9cafdff7858f3925007e4fa1e7ac3b591a0bd045@45.130.104.142:26656,58d7fc67e12548f3f1ddda3bbe6000ae3d9d638c@85.10.198.169:13656,bab17bf921c3bc6882dc0d37ed1ec9da9135a84c@109.123.236.225:13656,c7f6c0ca34fd69f41e8c7b0ee4d0e18e17a03d5c@185.250.149.121:26656,896c70ce52e6c88313048c9a63fcb9e7f0277144@178.208.86.44:46656,9e115998aa7265e433532366cfd05ad9af523458@38.242.201.87:26656,e84c51a539d705787644e235faab6bccd4b73bdd@5.61.33.18:26656,33f4b7f56b6708526f0638162f020394de0ce5e9@65.21.229.33:28656,df5a117c4e2f5d047b57552d71d45e8ea4a30f2c@185.239.209.135:26656,98f1c8de34db535585bfa390151b1d2ab323dc31@167.86.99.207:26656,038eef443b6bab9c28f9109599cd8733b3eb8dff@65.21.185.92:26656,d31acf73c9b1ecf3e7ed78ab2819c3ab40850db0@135.181.116.109:29886,67be97f5ef69a4f149fbef7970ba888e5b2c2cff@65.108.231.124:16656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.nolus/config/config.toml
SEEDS="3f472746f46493309650e5a033076689996c8881@nolus-testnet.rpc.kjnodes.com:43659"
sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $CONFIG_TOML

APP_TOML=$HOME/.nolus/config/app.toml
sed -i 's|^pruning *=.*|pruning = "nothing"|g' $APP_TOML
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $CONFIG_TOML
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $CONFIG_TOML
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025unls"|g' $APP_TOML

PORT=30
CLIENT_TOML=$HOME/.nolus/config/client.toml
sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):$PORT_PPROF_LADDR\"/" $CONFIG_TOML
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:266${PORT}\"%laddr = \"tcp://0.0.0.0:${PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${PORT}660\"%" $HOME/.cascadiad/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${PORT}317\"%; s%^address = \":8080\"%address = \":${PORT}080\"%; s%^address = \"0.0.0.0:${PORT}90\"%address = \"0.0.0.0:${PORT}090\"%; s%^address = \"0.0.0.0:${PORT}91\"%address = \"0.0.0.0:${PORT}091\"%" $HOME/.cascadiad/config/app.toml
sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:${PORT}657\"%" $CLIENT_TOML

echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/nolus.service  > /dev/null <<EOF
[Unit]
Description=Nolus node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nolusd) start
Restart=always
RestartSec=10
LimitNOFILE=10000
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
sudo systemctl enable nolusd
sudo systemctl start nolusd

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
  echo -e "\033[0;32m Update Heartbeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Heartbeat failed\033[0m"
fi

if [[ `service filebeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Filebeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Filebeat failed\033[0m"
fi

if [[ `service nolus status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"

echo -e "\033[0;31m You can check logs:\033[0m tail -f /var/log/nolus"