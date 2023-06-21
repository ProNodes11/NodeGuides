#!/bin/bash

NAMADA_TAG="v0.17.3"
TM_HASH="v0.1.4-abciplus"
NAMADA_CHAIN_ID="public-testnet-9.0.5aa315d1a22"

if [ ! $VALIDATOR_ALIAS ]; then
	read -p "Enter validator name: " VALIDATOR_ALIAS
	echo 'export VALIDATOR_ALIAS='\"${VALIDATOR_ALIAS}\" >> $HOME/.bash_profile
fi
echo -e 'Setting up swapfile...\n'
curl -s https://api.nodes.guru/swap8.sh | bash
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install make clang pkg-config git-core libssl-dev build-essential libclang-12-dev git jq ncdu bsdmainutils htop -y < "/dev/null"

echo -e '\n\e[42mInstall Rust\e[0m\n' && sleep 1
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
wget -O go1.19.4.linux-amd64.tar.gz https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz && sudo rm go1.19.4.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
cd $HOME && sudo rm -rf $HOME/namada
wget -O namada-v0.17.3-Linux-x86_64.tar.gz https://github.com/anoma/namada/releases/download/v0.17.3/namada-v0.17.3-Linux-x86_64.tar.gz
tar xvf namada-v0.17.3-Linux-x86_64.tar.gz
sudo mv namada-v0.17.3-Linux-x86_64/namada /usr/local/bin/
sudo mv namada-v0.17.3-Linux-x86_64/namada[c,n,w] /usr/local/bin/
#git clone https://github.com/anoma/namada
#cd namada
#git checkout $NAMADA_TAG
#make build-release
#sudo mv target/release/namada /usr/local/bin/
#sudo mv target/release/namada[c,n,w] /usr/local/bin/

#cd $HOME && sudo rm -rf tendermint
#git clone https://github.com/heliaxdev/tendermint
#cd tendermint
#git checkout $TM_HASH
#make build
#sudo mv build/tendermint /usr/local/bin/
cd $HOME
namada client utils join-network --chain-id $NAMADA_CHAIN_ID
NAMADA_CMT_STDOUT=true TM_LOG_LEVEL=p2p:none,pex:error namada ledger run
sleep 3
echo "[Unit]
Description=Namada Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.local/share/namada
Type=simple
ExecStart=/usr/local/bin/namada --base-dir=$HOME/.local/share/namada node ledger run
Environment=NAMADA_TM_STDOUT=true
RemainAfterExit=no
Restart=always
RestartSec=5s
LimitNOFILE=65535
StandardOutput=append:/var/log/node-namada
StandardError=append:/var/log/node-namada
[Install]
WantedBy=multi-user.target" > $HOME/namadad.service
sudo mv $HOME/namadad.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Namada-node
  hosts: ['$(wget -qO- eth0.me):26657']
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
    
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service namadad status | grep active` =~ "running" ]]; then
	  echo -e "Your namada node \e[32minstalled and works\e[39m!"
	    echo -e "You can check node status by the command \e[7mservice namadad status\e[0m"
	      echo -e "Press \e[7mQ\e[0m for exit from status menu"
      else
	        echo -e "Your namada node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
