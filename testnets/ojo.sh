#!/bin/bash

read -r -p "Enter node moniker: " MONIKER

PORT=34

echo -e "\033[0;31m Go checking\033[0m"
if go version >/dev/null 2>&1;
then
 echo -e "\033[0;31m Go is already installed\033[0m"
else
  ver="1.19.9" && \
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
  sudo rm -rf /usr/local/go && \
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
  rm "go$ver.linux-amd64.tar.gz" && \cd
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  echo -e "\033[0;31m Go installed $(go version) \033[0m"
fi

echo -e "\033[0;31m Project binaries \033[0m"
cd $HOME
rm -rf ojo
git clone https://github.com/ojo-network/ojo.git
cd ojo
git checkout v0.3.0-rc3

make build

mkdir -p $HOME/.ojo/cosmovisor/genesis/bin
mv build/ojod $HOME/.ojo/cosmovisor/genesis/bin/
rm -rf build

sudo ln -s $HOME/.ojo/cosmovisor/genesis $HOME/.ojo/cosmovisor/current -f
sudo ln -s $HOME/.ojo/cosmovisor/current/bin/ojod /usr/local/bin/ojod -f

echo -e "\033[0;31m Cosmos\033[0m"
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/ojo.service > /dev/null << EOF
[Unit]
Description=ojo node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.ojo"
Environment="DAEMON_NAME=ojod"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.ojo/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable ojo.service

ojod config chain-id agamotto
ojod config keyring-backend test
ojod config node tcp://localhost:15057ojod 

echo -e "\033[0;31m Initialize\033[0m"
init $MONIKER --chain-id agamotto

curl -Ls https://snapshots.kjnodes.com/ojo-testnet/genesis.json > $HOME/.ojo/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/ojo-testnet/addrbook.json > $HOME/.ojo/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@ojo-testnet.rpc.kjnodes.com:15059\"|" $HOME/.ojo/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0uojo\"|" $HOME/.ojo/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.ojo/config/app.toml

# Add seeds
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@ojo-testnet.rpc.kjnodes.com:15059\"|" $HOME/.ojo/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0uojo\"|" $HOME/.ojo/config/app.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:266${PORT}\"%laddr = \"tcp://0.0.0.0:${PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${PORT}660\"%" $HOME/.ojo/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${PORT}17\"%; s%^address = \":8080\"%address = \":${PORT}80\"%; s%^address = \"0.0.0.0:${PORT}90\"%address = \"0.0.0.0:${PORT}90\"%; s%^address = \"0.0.0.0:${PORT}91\"%address = \"0.0.0.0:${PORT}91\"%" $HOME/.ojo/config/app.toml
sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:${PORT}657\"%" $HOME/.ojo/config/client.toml

echo -e "\033[0;31m Downloading snapshot\033[0m"
curl -L https://snapshots.kjnodes.com/ojo-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.ojo
[[ -f $HOME/.ojo/data/upgrade-info.json ]] && cp $HOME/.ojo/data/upgrade-info.json $HOME/.ojo/cosmovisor/genesis/upgrade-info.json

echo -e "\033[0;31m Starting node\033[0m"
sudo systemctl start ojo.service && sudo journalctl -u ojo.service -f --no-hostname -o cat


