#!/bin/bash

while true
do

# Logo

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

# Menu

PS3='Select an action: '
options=(
"Install monitoring"
"Install Go"
"Install docker"
"Install Rust"
"Prepare server"
"Node repp"
"Install Nibiru"
"Install Starknet"
"Install Lambdavm"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install monitoring")
echo -e "\033[0;31m Install Grafana now\033[0m"
if grafana-cli -v >/dev/null 2>&1; then
    echo -e "\033[0;31m Grafana is already installed\033[0m"
else
pass=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-20} | head -n 1)
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana -y
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server.service
fi
echo -e "\033[0;31m Install Prometheus now\033[0m"
if prometheus --version >/dev/null 2>&1; then
    echo -e "\033[0;31m Prometheus is already installed\033[0m"
else
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
sudo mkdir /var/lib/prometheus
sudo mkdir -p /etc/prometheus
sudo apt update
sudo apt -y install wget curl
mkdir -p /tmp/prometheus && cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
tar xvf prometheus*.tar.gz
cd prometheus*/
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
cd $HOME
touch /etc/prometheus/prometheus.yml
cat << EOF >> /etc/prometheus/prometheus.yml
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  external_labels:
      monitor: 'example'
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
- job_name: 'node-exporter'
  scrape_interval: 5s
  static_configs:
    - targets: ['localhost:9100']
- job_name: 'cosmos-node'
  scrape_interval: 5s
  static_configs:
    - targets: ['localgost:26660']
EOF

sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo chown -R prometheus:prometheus /var/lib/prometheus/
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
fi
echo -e "\033[0;31m Install Node-exporter now\033[0m"
if test -f "/etc/systemd/system/node_exporter.service"; then
    echo -e "\033[0;31m Prometheus is already installed\033[0m"
else
sudo useradd --system --shell /bin/false node_exporter
curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz \
  | sudo tar -zxvf - -C /usr/local/bin --strip-components=1 node_exporter-1.3.1.linux-amd64/node_exporter \
  && sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo tee /etc/systemd/system/node_exporter.service <<"EOF"
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
Group=node_exporter
EnvironmentFile=-/etc/sysconfig/node_exporter
ExecStart=/usr/local/bin/node_exporter $OPTIONS

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload 
sudo systemctl start node_exporter 
sudo systemctl enable node_exporter
fi
echo -e "\033[0;31m Instaled Prometheus-Grafana + Node-exporter\033[0m"
echo -e "\033[0;31m Node-exporter         - \033[0m http://$(wget -qO- eth0.me):9100"
echo -e "\033[0;31m Prometheus            - \033[0m http://$(wget -qO- eth0.me):9090/targets?search="
echo -e "\033[0;31m Grafana               - \033[0m http://$(wget -qO- eth0.me):3000"
echo -e "\033[0;31m Grafana login         - \033[0m admin"
echo -e "\033[0;31m Grafana pass          - \033[0m $pass"
break
;;


"Install Go")
if go version >/dev/null 2>&1; then
echo -e "\033[0;31m Go is already installed\033[0m"
else
wget -O go1.19.2.linux-amd64.tar.gz https://golang.org/dl/go1.19.2.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz && rm go1.19.2.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
echo -e "\033[0;31m $(go version) \033[0m"
fi
break
;;

"Install docker")
echo -e "\033[0;31m Install Docker now\033[0m"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo service docker start
sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo -e "\033[0;31m $(docker compose version)\033[0m"
echo -e "\033[0;31m $(docker version)\033[0m"
break
;;

"Install Rust")
if cargo --version >/dev/null 2>&1; then
echo -e "\033[0;31m Rust is already installed\033[0m"
else
echo -e "\033[0;31m Install Rust now\033[0m"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
break
;;

"Prepare server")
echo -e "\033[0;31m Server preparing\033[0m"
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop screen unzip bc fail2ban htop -y
break
;;

"Node repp")
echo -e "\033[0;31m Nibiru rep  - \033[0m https://github.com/NibiruChain/nibiru"
echo -e "\033[0;31m Nibiru docs - \033[0m https://docs.nibiru.fi/run-nodes/testnet/"
echo -e "\033[0;31m Sui rep     - \033[0m https://github.com/MystenLabs/sui"
echo -e "\033[0;31m Sui docs    - \033[0m https://docs.sui.io/devnet/build/fullnode"
echo -e "\033[0;31m Wait        - \033[0m"
break
;;

"Install Lambdavm")
echo -e "\033[0;31m	Enter Moniker:\033[0m"
read MONIKER
echo export MONIKER=${MONIKER} >> $HOME/.bash_profile
git clone https://github.com/LambdaIM/lambdavm.git
cd lambdavm && git checkout v1.0.0
make install
lambdavm config chain-id lambdatest_92001-2
lambdavm init $MONIKER --chain-id lambdatest_92001-2
wget https://raw.githubusercontent.com/LambdaIM/testnets/main/lambdatest_92001-2/genesis.json
mv genesis.json ~/.lambdavm/config/
PEERS=`curl -sL https://raw.githubusercontent.com/LambdaIM/testnets/main/lambdatest_92001-2/peers.txt | sort -R | head -n 10 | awk '{print $1}' | paste -s -d, -`
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" ~/.lambdavm/config/config.toml
echo "[Unit]
Description=StarkNet
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which lambdavm)
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/lambdavm.service
mv $HOME/lambdavm.service /etc/systemd/system/
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable lambdavm
sudo systemctl restart lambdavm
break
;;

"Install Starknet")
echo -e "\033[0;31m	Enter Alhemy endpoint:\033[0m"
read ALCHEMY
echo export ALCHEMY=${ALCHEMY} >> $HOME/.bash_profile
sudo apt update -y && sudo apt install curl git tmux python3 python3-venv python3-dev build-essential libgmp-dev pkg-config libssl-dev -y
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
git clone https://github.com/eqlabs/pathfinder.git
cd pathfinder
git fetch
git checkout v0.4.5
cd $HOME/pathfinder/py
python3 -m venv .venv
source .venv/bin/activate
PIP_REQUIRE_VIRTUALENV=true pip install --upgrade pip
PIP_REQUIRE_VIRTUALENV=true pip install -e .[dev]
#pip install --upgrade pip
pytest
cd $HOME/pathfinder/
cargo +stable build --release --bin pathfinder

sleep 2
source $HOME/.bash_profile
mv ~/pathfinder/target/release/pathfinder /usr/local/bin/ || exit

echo "[Unit]
Description=StarkNet
After=network.target

[Service]
User=$USER
Type=simple
WorkingDirectory=$HOME/pathfinder/py
ExecStart=/bin/bash -c \"source $HOME/pathfinder/py/.venv/bin/activate && /usr/local/bin/pathfinder --http-rpc=\"0.0.0.0:9545\" --ethereum.url $ALCHEMY\"
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/starknetd.service
mv $HOME/starknetd.service /etc/systemd/system/
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable starknetd
sudo systemctl restart starknetd
break
;;

"Exit")
exit
esac
done
done
