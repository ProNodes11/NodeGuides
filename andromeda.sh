#!/bin/bash

PORT=33
VERSION_TAG="galileo-3-v1.1.0-beta1"
CHAIN_ID=galileo-3
read -r -p "Enter node moniker: " NODE_MONIKER

git clone https://github.com/andromedaprotocol/andromedad.git
cd andromedad
git checkout $VERSION_TAG

# Install binaries
make install

# Initialize the node
andromedad init $NODE_MONIKER --chain-id $CHAIN_ID

mkdir -p $HOME/.andromedad/cosmovisor/genesis/bin
cp ~/go/bin/andromedad $HOME/.andromedad/cosmovisor/genesis/bin/

# Download genesis and addrbook
curl -s https://raw.githubusercontent.com/andromedaprotocol/testnets/galileo-3/genesis.json > $HOME/.andromedad/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/andromeda-testnet/addrbook.json > $HOME/.andromedad/config/addrbook.json


# Set node configuration
andromedad config chain-id galileo-3
andromedad config keyring-backend test

sed -i 's|^pruning *=.*|pruning = "nothing"|g' /root/.andromedad/config/app.toml
sed -i 's|^indexer *=.*|indexer = "null"|' /root/.andromedad/config/config.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${PORT}660\"%" $HOME/.andromedad/config/config.toml 
sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${PORT}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${PORT}17\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${PORT}45\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${PORT}46\"%; s%^address = \"127.0.0.1:8545\"%address = \"127.0.0.1:${PORT}45\"%; s%^ws-address = \"127.0.0.1:8546\"%ws-address = \"127.0.0.1:${PORT}46\"%" $HOME/.andromedad/config/app.toml
sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:${PORT}657\"%" $HOME/.andromedad/config/client.toml 

curl -L https://snapshots.kjnodes.com/andromeda-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.andromedad
[[ -f $HOME/.andromedad/data/upgrade-info.json ]] && cp $HOME/.andromedad/data/upgrade-info.json $HOME/.andromedad/cosmovisor/genesis/upgrade-info.json


# Download and install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0

# Create service
sudo tee /etc/systemd/system/andromedad.service > /dev/null << EOF
[Unit]
Description=andromeda-testnet node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.andromedad"
Environment="DAEMON_NAME=andromedad"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.andromedad/cosmovisor/current/bin"
StandardOutput=append:/var/log/node-andromeda
StandardError=append:/var/log/node-andromeda

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Andromeda-node
  hosts: ['http://$(wget -qO- eth0.me):$(echo $PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Andromeda"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-andromeda
    fields:
      host: $HOSTNAME
      name: andromeda
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat


systemctl daemon-reload
systemctl enable andromedad
systemctl restart andromedad

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

if [[ `service andromedad status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
