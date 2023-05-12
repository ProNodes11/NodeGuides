#!/bin/bash

wget -O subspace-cli https://github.com/subspace/subspace-cli/releases/download/v0.3.3-alpha/subspace-cli-ubuntu-x86_64-v3-v0.3.3-alpha 
sudo chmod +x subspace-cli
sudo mv subspace-cli /usr/local/bin/
sudo rm -rf $HOME/.config/subspace-cli
/usr/local/bin/subspace-cli init

sleep 1
sudo tee /etc/systemd/system/subspace.service  > /dev/null <<EOF
[Unit]
Description=Subspace Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/subspace-cli farm --verbose
Restart=on-failure
LimitNOFILE=1024000
StandardOutput=append:/var/log/node-subspace
StandardError=append:/var/log/node-subspace

[Install]
WantedBy=multi-user.target
EOF 

sudo systemctl daemon-reload
sudo systemctl enable subspaced
sudo systemctl restart subspaced

if [[ `service subspaced status | grep active` =~ "running" ]]; then
  echo -e "Your Subspace node \e[32minstalled and works\e[39m!"
else
  echo -e "Your Subspace node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
