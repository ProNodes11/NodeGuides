#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

NIBIRU_PORT=29
CHAIN_ID=nibiru-itn-2
SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/nibiru-testnet/info.json | jq -r .fileName)

if go version >/dev/null 2>&1;
then
 echo -e "\033[0;31m Go is already installed\033[0m"
else
  ver="1.20.3" && \
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
  sudo rm -rf /usr/local/go && \
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
  rm "go$ver.linux-amd64.tar.gz" && \cd
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  echo -e "\033[0;31m Go installed $(go version) \033[0m"
fi

read -p "Enter moniker for node: " MONIKER

echo -e "\033[0;33m Install node\033[0m"
rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru
cd nibiru || return
git checkout v0.21.10
make install

echo -e "\033[0;33m Configuring node\033[0m"
nibid config keyring-backend test
nibid config chain-id nibiru-itn-2
nibid init $MONIKER --chain-id $CHAIN_ID
curl -s https://rpc.itn-2.nibiru.fi/genesis | jq -r .result.genesis > $HOME/.nibid/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/nibiru-testnet/addrbook.json > $HOME/.nibid/config/addrbook.json
nibid config node tcp://localhost:29657
curl "https://snapshots-testnet.nodejumper.io/nibiru-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C $HOME/.nibid


echo -e "\033[0;33m Install Cosmovisor\033[0m"
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

echo -e "\033[0;33m Configuring Cosmovisor\033[0m"
mkdir -p /root/.nibid/cosmovisor/genesis/bin
mkdir -p /root/.nibid/cosmovisor/upgrades

cp /root/go/bin/nibid /root/.nibid/cosmovisor/genesis/bin


echo -e "\033[0;33m Creating service\033[0m"
sudo tee /etc/systemd/system/nibid.service  > /dev/null <<EOF
[Unit]
Description=Nibiru node 
After=network-online.target

[Service]
User=root
ExecStart=/root/go/bin/cosmovisor start
Restart=always
RestartSec=10
LimitNOFILE=10000
Environment="DAEMON_NAME=nibid"
Environment="DAEMON_HOME=$HOME/.nibid"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
StandardOutput=append:/var/log/node-nibiru
StandardError=append:/var/log/node-nibiru

[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;33m Updating configs\033[0m"

echo -e "\033[0;33m Update node config\033[0m"
sed -i 's|^indexer *=.*|indexer = "null"|' ~/.nibid/config/config.toml
sed -i.bak -e 's|^pruning *=.*|pruning = "custom"|; s|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|; s|^pruning-keep-every *=.*|pruning-keep-every = "0"|; s|^pruning-interval *=.*|pruning-interval = "10"|' $HOME/.nibid/config/app.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NIBIRU_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${NIBIRU_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NIBIRU_PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NIBIRU_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NIBIRU_PORT}660\"%" $HOME/.nibid/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${NIBIRU_PORT}17\"%; s%^address = \":8080\"%address = \":${NIBIRU_PORT}80\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NIBIRU_PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NIBIRU_PORT}91\"%" $HOME/.nibid/config/app.toml

echo -e "\033[0;33m Update Heartbeat config\033[0m"
echo "- type: http
  name: Nibiru-node
  hosts: ['http://$(wget -qO- eth0.me):$(echo $NIBIRU_PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Nibiru"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-nibiru
    fields:
      host: $HOSTNAME
      name: nibiru
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

echo -e "\033[0;32m Starting node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable nibid
sudo -S systemctl start nibid

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

if [[ `service nibid status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
