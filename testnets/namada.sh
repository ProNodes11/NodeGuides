#!/bin/bash

echo -e "\033[0;33m Server preparing \033[0m"
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libclang-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool uidmap dbus-user-session -y
wget https://go.dev/dl/go1.19.5.linux-amd64.tar.gz; \
rm -rv /usr/local/go; \
tar -C /usr/local -xzf go1.19.5.linux-amd64.tar.gz && \
rm -v go1.19.5.linux-amd64.tar.gz && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

cd $HOME
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
. $HOME/.cargo/env
curl https://deb.nodesource.com/setup_16.x | sudo bash
sudo apt install cargo nodejs -y < "/dev/null"
cargo --version
apt install unzip && apt -y remove protobuf-compiler
cd && mkdir protoc && cd protoc
wget https://github.com/protocolbuffers/protobuf/releases/download/v23.0/protoc-23.0-linux-x86_64.zip
unzip protoc-23.0-linux-x86_64.zip
cp bin/protoc /usr/local/bin/

echo -e "\033[0;33m Node installing \033[0m"

read -p "Enter moniker for node: " VALIDATOR_ALIAS
CHAIN_ID_NAMADA=public-testnet-9.0.5aa315d1a22
WALLET_NAMADA=wallet
BASE_DIR_NAMADA=$HOME/.local/share/namada

echo "export VALIDATOR_ALIAS="${VALIDATOR_ALIAS}"" >> $HOME/.bash_profile
echo "export CHAIN_ID_NAMADA="${CHAIN_ID_NAMADA}"" >> $HOME/.bash_profile
echo "export WALLET_NAMADA="${WALLET_NAMADA}"" >> $HOME/.bash_profile
echo "export BASE_DIR="${BASE_DIR_NAMADA}"" >> $HOME/.bash_profile

source $HOME/.bash_profile

mkdir $HOME/.local/share/namada

cd $HOME
git clone https://github.com/anoma/namada
cd namada
git checkout v0.17.3
make build-release
cp "$HOME/namada/target/release/namada" /usr/local/bin/namada && cp "$HOME/namada/target/release/namadac" /usr/local/bin/namadac && cp "$HOME/namada/target/release/namadan" /usr/local/bin/namadan && cp "$HOME/namada/target/release/namadaw" /usr/local/bin/namadaw
cp -r include/google $HOME/namada/proto/

namada --version

cd $HOME
git clone https://github.com/cometbft/cometbft.git
cd cometbft
git checkout v0.37.2
make install
cp $HOME/go/bin/cometbft /usr/local/bin/cometbft

cd $HOME
namada client utils join-network --chain-id $CHAIN_ID_NAMADA

wget "https://github.com/heliaxdev/anoma-network-config/releases/download/public-testnet-8.0.b92ef72b820/public-testnet-8.0.b92ef72b820.tar.gz"
tar xvzf "$HOME/public-testnet-8.0.b92ef72b820.tar.gz"

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
    
echo -e "\033[0;33m Running a service \033[0m" && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad

echo -e "\033[0;33m Done !\033[0m"
