#!/bin/bash


read -p "Enter password for elastic: " PASSWORD

echo -e "\033[0;31m Updating \033[0m"
apt update 
apt install curl apt-transport-https iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
echo -e "\033[0;31m Go installing \033[0m"
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

echo -e "\033[0;31m Filebeat installing \033[0m"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update && sudo apt-get install filebeat
echo "output.elasticsearch:
  hosts: ["lastic.stakeme.io"]
  protocol: "https"
  username: "elastic"
  password: "$PASSWORD"

filebeat.inputs:" > /etc/metricbeat/filebeat.yml
sudo systemctl enable filebeat && sudo systemctl restart filebeat

echo -e "\033[0;31m Metricbeat installing \033[0m"
sudo apt-get update && sudo apt-get install metricbeat
rm /etc/metricbeat/metricbeat.yml
echo "metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression

setup.kibana:

output.elasticsearch:
  hosts: ["lastic.stakeme.io"]
  protocol: "https"
  username: "elastic"
  password: "$PASSWORD"
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~" > /etc/metricbeat/metricbeat.yml
  sudo systemctl enable metricbeat && sudo systemctl restart metricbeat

echo -e "\033[0;31m Heartbeat installing \033[0m"
sudo apt-get update && sudo apt-get install heartbeat
rm /etc/heartbeat/heartbeat.yml
echo "heartbeat.config.monitors:
  path: \${path.config}/monitors.d/*.yml
  reload.enabled: false
  reload.period: 5s
  setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression

output.elasticsearch:
  hosts: ["lastic.stakeme.io"]
  protocol: "https"
  username: "elastic"
  password: "$PASSWORD"

processors:
  - add_observer_metadata:
  
  heartbeat.monitors:" > /etc/heartbeat/heartbeat.yml
  sudo systemctl enable heartbeat && sudo systemctl restart heartbeat
