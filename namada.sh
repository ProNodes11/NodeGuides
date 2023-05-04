#!/bin/bash

NAMADA_TAG="v0.15.1"
TM_HASH="v0.1.4-abciplus"
NAMADA_CHAIN_ID="public-testnet-7.0.3c5a38dc983"

echo -e "\033[0;31m Server preparing\033[0m"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

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

echo -e "\033[0;31m Installing software\033[0m"
cd $HOME && sudo rm -rf $HOME/namada
git clone https://github.com/anoma/namada
cd namada
git checkout $NAMADA_TAG
make build-release
sudo mv target/release/namada /usr/local/bin/

cd $HOME && sudo rm -rf tendermint
git clone https://github.com/heliaxdev/tendermint
cd tendermint
git checkout $TM_HASH
make build
sudo mv build/tendermint /usr/local/bin/
cd $HOME
namada client utils join-network --chain-id $NAMADA_CHAIN_ID

echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/namada.service > /dev/null <<EOF
[Unit]
Description=Namafa Node
After=network-online.target
[Service]
User=$USER
ExecStart=${HOME}/go/bin/namada start
Restart=always
RestartSec=3
LimitNOFILE=infinity
LimitNPROC=infinity
StandardOutput=append:/var/log/node-namada
StandardError=append:/var/log/node-namada

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable namada
sudo systemctl restart namada

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Namada-node
  hosts: ['localhost:26657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Namada"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-namada
    fields:
      host: $HOSTNAME
      name: namada
    encoding: plain" >> /etc/filebeat/filebeat.yml
systemctl restart filebeat

systemctl daemon-reload
systemctl enable namada
systemctl restart namada

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

if [[ `service namada status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"
