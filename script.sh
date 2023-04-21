#!/bin/bash

echo "Enter the moniker: "
read MONIKER_CASCADIA

CHAIN_ID_CASCADIA=cascadia_6102-1
PORT_CASCADIA=39


if [ $(dpkg-query -W -f='${Status}' go 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  ver="1.20.3" && \
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
  sudo rm -rf /usr/local/go && \
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
  rm "go$ver.linux-amd64.tar.gz" && \cd
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
  source $HOME/.bash_profile && \
  go version
fi

git clone https://github.com/cascadiafoundation/cascadia
cd cascadia
git checkout v0.1.1
make install

wget -O $HOME/.cascadiad/config/genesis.json   https://anode.team/Cascadia/test/genesis.json

sudo tee /etc/systemd/system/cascadiad.service > /dev/null <<EOF
[Unit]
Description=cascadiad
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cascadiad) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cascadiad