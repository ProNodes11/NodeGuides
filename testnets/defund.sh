#!/bin/bash

echo "Enter the moniker: "
read MONIKER
PORT=32
DEFUNd_TAG="v0.2.6"

echo -e "\033[0;31m Server preparing\033[0m"
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

# Clone project repository
cd $HOME
rm -rf defund
git clone https://github.com/defund-labs/defund.git
cd defund
git checkout v0.2.6

# Build binaries
make build

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.defund/cosmovisor/genesis/bin
mv build/defundd $HOME/.defund/cosmovisor/genesis/bin/
rm -rf build

# Create application symlinks
sudo ln -s $HOME/.defund/cosmovisor/genesis $HOME/.defund/cosmovisor/current -f
sudo ln -s $HOME/.defund/cosmovisor/current/bin/defundd /usr/local/bin/defundd -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0

indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.defund/config/config.toml

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:266${PORT}\"%laddr = \"tcp://0.0.0.0:${PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${PORT}660\"%" $HOME/.defund/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${PORT}17\"%; s%^address = \":8080\"%address = \":${PORT}80\"%; s%^address = \"0.0.0.0:${PORT}90\"%address = \"0.0.0.0:${PORT}90\"%; s%^address = \"0.0.0.0:${PORT}91\"%address = \"0.0.0.0:${PORT}91\"%" $HOME/.defund/config/app.toml

echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/defund.service > /dev/null <<EOF
[Unit]
Description=defund-testnet node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.defund"
Environment="DAEMON_NAME=defundd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.defund/cosmovisor/current/bin"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
StandardOutput=append:/var/log/node-defund
StandardError=append:/var/log/node-defund

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable defund
sudo systemctl start defund

curl -Ls https://snapshots.kjnodes.com/defund-testnet/genesis.json > $HOME/.defund/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/defund-testnet/addrbook.json > $HOME/.defund/config/addrbook.json

defund init $MONIKER --chain-id orbit-alpha-1

curl -L https://snapshots.kjnodes.com/defund-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.defund
[[ -f $HOME/.defund/data/upgrade-info.json ]] && cp $HOME/.defund/data/upgrade-info.json $HOME/.defund/cosmovisor/genesis/upgrade-info.json

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Defund-node
  hosts: ['http://$(wget -qO- eth0.me):$(echo $PORT)657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Defund"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-defund
    fields:
      host: $HOSTNAME
      name: defund
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

systemctl daemon-reload
systemctl enable defund
systemctl restart defund

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

if [[ `service defund status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
