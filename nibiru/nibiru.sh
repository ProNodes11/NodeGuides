#!/bin/bash

while true
do

# Logo

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

read -p "Enter pass for node: " PASS
echo 'export pass for mode='${PASS} >> $HOME/.bash_profile
read -p "Enter moniker for node: " MONIKER
echo 'export Moniker='${MONIKER} >> $HOME/.bash_profile
if go version >/dev/null 2>&1; then
echo -e "\033[0;31m Go is already installed\033[0m"
else
wget https://golang.org/dl/go1.18.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.18.2.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile
rm go1.18.2.linux-amd64.tar.gz
echo -e "\033[0;31m Go installed $(go version) \033[0m"
fi
echo -e "\033[0;31m Server preparing\033[0m"
sudo apt update && sudo apt upgrade -y > /dev/null
sudo apt install snapd lz4 curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils make htop bc -y > /dev/null
echo -e "\033[0;31m Install node\033[0m"
git clone https://github.com/NibiruChain/nibiru nibiru
cd nibiru
git checkout v0.16.3
make install
echo -e "\033[0;31m Configuring node\033[0m"
nibid init $MONIKER --chain-id nibiru-testnet-2 --home $PASS/.nibid
wget -O genesis.json https://snapshots.polkachu.com/testnet-genesis/nibiru/genesis.json --inet4-only
mv genesis.json $PASS/.nibid/config
wget -O addrbook.json https://snapshots.polkachu.com/testnet-addrbook/nibiru/addrbook.json --inet4-only
mv addrbook.json $PASS/.nibid/config
sed -i 's|^indexer *=.*|indexer = "null"|' $PASS/.lambdavm/config/config.toml
sed -i.bak -e 's|^pruning *=.*|pruning = "custom"|; s|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|; s|^pruning-keep-every *=.*|pruning-keep-every = "0"|; s|^pruning-interval *=.*|pruning-interval = "10"|' $PASS/.nibid/config/app.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:1111\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:26657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:6060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:26656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":26660\"%" $HOME/.lambdavm/config/config.toml && \
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:1317\"%; s%^address = \":8080\"%address = \":8080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:1090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:1091\"%" $HOME/.nibid/config/app.toml
echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/nibid.service  > /dev/null <<EOF
[Unit]
Description=Nibiru node 
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nibid) start --home $PASS/.nibid
Restart=always
RestartSec=10
LimitNOFILE=10000
StandardOutput=append:/var/log/nibid
StandardError=append:/var/log/nibid
[Install]
WantedBy=multi-user.target
EOF
echo -e "\033[0;31m Downloading snapshot\033[0m"
echo -e "\033[0;31m https://polkachu.com/testnets/nibiru/snapshots \033[0m"
read -p "Enter link for snapshot: " LINK
echo 'export link='${LINK} >> $HOME/.bash_profile
nibid tendermint unsafe-reset-all --home $PASS/.nibid --keep-addr-book
wget -O nibiru.tar.gz $LINK 
lz4 -c -d nibiru.tar.lz4  | tar -xvf -C $HOME/.nibid
rm -v nibiru.tar.lz4
echo -e "\033[0;31m Start node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable nibid
sudo -S systemctl start nibid
echo -e "\033[0;31m Node started \033[0m  "
echo -e "\033[0;31m Node RPC \033[0m           http://$(wget -qO- eth0.me):26657"
echo -e "\033[0;31m Node API \033[0m           http://$(wget -qO- eth0.me):1317"
echo -e "\033[0;31m You can check logs:\033[0m tail -f /var/log/nibid"
