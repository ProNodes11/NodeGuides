#!/bin/bash
curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash
read -p "Enter pass for node: " PASS
echo 'export pass for mode='${PASS} >> $HOME/.bash_profile
read -p "Moniker: " MONIKER
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
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils make htop bc -y > /dev/null
echo -e "\033[0;31m Install node\033[0m"
git clone https://github.com/LambdaIM/lambdavm.git lambdavm
cd lambdavm && git checkout v1.0.0
make install
echo -e "\033[0;31m Configuring node\033[0m"
lambdavm config chain-id lambdatest_92001-2 --home $PASS/.lambdavm
lambdavm init $MONIKER --chain-id lambdatest_92001-2 --home $PASS/.lambdavm
wget https://raw.githubusercontent.com/LambdaIM/testnets/main/lambdatest_92001-2/genesis.json
mv genesis.json $PASS/.lambdavm/config/
PEERS=`curl -sL https://raw.githubusercontent.com/LambdaIM/testnets/main/lambdatest_92001-2/peers.txt | sort -R | head -n 10 | awk '{print $1}' | paste -s -d, -`
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $PASS/.lambdavm/config/config.toml
sed -i 's|^indexer *=.*|indexer = "null"|' $PASS/.lambdavm/config/config.toml
sed -i.bak -e 's|^pruning *=.*|pruning = "custom"|; s|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|; s|^pruning-keep-every *=.*|pruning-keep-every = "0"|; s|^pruning-interval *=.*|pruning-interval = "10"|' $PASS/.lambdavm/config/app.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:1111\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:26657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:6060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:26656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":26660\"%" $HOME/.lambdavm/config/config.toml && \
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:1317\"%; s%^address = \":8080\"%address = \":8080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:1090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:1091\"%" $HOME/.lambdavm/config/app.toml
echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/lambdavm.service  > /dev/null <<EOF
[Unit]
Description=Nibiru node 
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lambdavm) start --home $PASS/.lambdavm
Restart=always
RestartSec=10
LimitNOFILE=10000
StandardOutput=append:/var/log/lambdavm
StandardError=append:/var/log/lambdavm
[Install]
WantedBy=multi-user.target
EOF
echo -e "\033[0;31m Synking node\033[0m"
lambdavm tendermint unsafe-reset-all --home $PASS/.lambdavm
peers="90b4449c0820e0f7a69884683aa931b37dbce406@144.76.97.35:25656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $PASS/.lambdavm/config/config.toml
SNAP_RPC=144.76.97.35:25657
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $PASS/.lambdavm/config/config.toml
echo -e "\033[0;31m Start node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable lambdavm
sudo -S systemctl start lambdavm
echo -e "\033[0;31m Node started \033[0m  "
echo -e "\033[0;31m Node RPC \033[0m           http://$(wget -qO- eth0.me):26657"
echo -e "\033[0;31m Node API \033[0m           http://$(wget -qO- eth0.me):1317"
echo -e "\033[0;31m You can check logs:\033[0m tail -f /var/log/lambdavm"
