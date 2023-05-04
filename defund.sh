#!/bin/bash

echo "Enter the moniker: "
read MONIKER

echo -e "\033[0;31m Server preparing\033[0m"
apt update && apt upgrade -y
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y


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

echo -e "\033[0;31m Install node\033[0m"
git clone https://github.com/defund-labs/defund
cd defund
git checkout v0.2.6
make install

echo -e "\033[0;31m Configuring node\033[0m"
defundd config keyring-backend test
defundd config chain-id orbit-alpha-1
defundd init $MONIKER --chain-id orbit-alpha-1

curl -s https://raw.githubusercontent.com/defund-labs/testnet/main/defund-private-4/genesis.json > ~/.defund/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/defund-testnet/addrbook.json > $HOME/.defund/config/addrbook.json

PEERS="d837b7f78c03899d8964351fb95c78e84128dff6@174.83.6.129:30791,f03f3a18bae28f2099648b1c8b1eadf3323cf741@162.55.211.136:26656,f8fa20444c3c56a2d3b4fdc57b3fd059f7ae3127@148.251.43.226:56656,70a1f41dea262730e7ab027bcf8bd2616160a9a9@142.132.202.86:17000"
sed -i -e "s/^seeds =./seeds = \"$SEEDS\"/; s/^persistent_peers =./persistent_peers = \"$PEERS\"/" $HOME/.defund/config/config.toml

PORT=32
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:266${PORT}\"%laddr = \"tcp://0.0.0.0:${PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${PORT}660\"%" $HOME/.cascadiad/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${PORT}317\"%; s%^address = \":8080\"%address = \":${PORT}080\"%; s%^address = \"0.0.0.0:${PORT}90\"%address = \"0.0.0.0:${PORT}090\"%; s%^address = \"0.0.0.0:${PORT}91\"%address = \"0.0.0.0:${PORT}091\"%" $HOME/.cascadiad/config/app.toml

echo -e "\033[0;31m Creating service\033[0m"
sudo tee /etc/systemd/system/defund.service > /dev/null <<EOF
[Unit]
Description=Defund Node
After=network-online.target
[Service]
User=$USER
ExecStart=${HOME}/go/bin/defundd start
Restart=always
RestartSec=3
LimitNOFILE=infinity
LimitNPROC=infinity
StandardOutput=append:/var/log/node-defund
StandardError=append:/var/log/node-defund

[Install]
WantedBy=multi-user.target
EOF

defundd tendermint unsafe-reset-all --home $HOME/.defund --keep-addr-book
SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/defund-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/defund-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.defund"

sudo systemctl daemon-reload
sudo systemctl enable defundd
sudo systemctl start defundd

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Defund-node
  hosts: ['$(wget -qO- eth0.me):$(echo $PORT)657']
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
  echo -e "\033[0;32m Update Heartbeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Heartbeat failed\033[0m"
fi

if [[ `service filebeat status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Update Filebeat sucsesfull\033[0m"
else
  echo -e "\033[0;31m Update Filebeat failed\033[0m"
fi

if [[ `service defund status | grep active` =~ "running" ]]; then
  echo -e "\033[0;32m Node running\033[0m"
else
  echo -e "\033[0;31m Node not working\033[0m"
fi

echo -e "\033[0;33m Script ended\033[0m"

echo -e "\033[0;31m You can check logs:\033[0m tail -f /var/log/defund"