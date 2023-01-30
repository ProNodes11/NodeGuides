#!/bin/bash
curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash
read -p "Enter mnemonic for node: " Mnemonic
echo 'export Mnemonic for mode='${Mnemonic} >> $HOME/.bash_profile
read -p "Discord: " Discord
echo 'export Discord='${Discord} >> $HOME/.bash_profile

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y build-essential libssl-dev cmake

if cargo version >/dev/null 2>&1; then
echo -e "\033[0;31m Rust is already installed\033[0m"
else
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
fi

if bazuka -V >/dev/null 2>&1; then
echo -e "\033[0;31m Bazuka is already installed\033[0m"
else
echo -e "\033[0;31m Downloading node\033[0m"
git clone https://github.com/ziesha-network/bazuka
cd bazuka
cargo install --path .
fi
bazuka init --network pelmeni --bootstrap 65.108.193.133:8765 --mnemonic "$Mnemonic" --external $(wget -qO- eth0.me):8765
sudo tee /etc/systemd/system/ziesha.service  > /dev/null <<EOF
[Unit]
Description=Ziesha Node
After=network.target

[Service]
Type=simple
User=root
ExecStart=$(which bazuka) node start --discord-handle "$Discord"
Restart=always
RestartSec=3
LimitNOFILE=10000
StandardOutput=append:/var/log/ziesha
StandardError=append:/var/log/ziesha
[Install]
WantedBy=multi-user.target
EOF

echo -e "\033[0;31m Starting node\033[0m"
sudo -S systemctl daemon-reload
sudo -S systemctl enable ziesha
sudo -S systemctl start ziesha
echo -e "\033[0;31m Node started \033[0m  "
echo -e "\033[0;31m You can check logs:\033[0m tail -f /var/log/ziesha"
