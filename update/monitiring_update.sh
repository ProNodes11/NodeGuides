#!/bin/bash

NIBIRU_DIR=/$HOME/.nibid/data/priv_validator_state.json
DEFUND_DIR=/$HOME/.defund/data/priv_validator_state.json
CASCADIA_DIR=/$HOME/.cascadiad/data/priv_validator_state.json
BABYLON_DIR=/$HOME/.babylond/data/priv_validator_state.json
ANDROMEDA_DIR=/$HOME/.andromedad/data/priv_validator_state.json
OJO_DIR=/$HOME/.ojo/data/priv_validator_state.json
SHARD_NODE=/$HOME/.shardeum/shell.sh
MUON_NODE=/$HOME/muon-node/docker-compose.yml

if test -f "$NIBIRU_DIR"; then
  echo "- type: http
    name: Nibiru-node
    hosts: ['http://$(wget -qO- eth0.me):29657']
    schedule: '@every 60s'
    timeout: 1s
    wait: 1s
    ssl:
      verification_mode: none
    tags: ["Nibiru"]" >> /etc/heartbeat/heartbeat.yml
  systemctl restart heartbeat

  echo "  - type: log
      format: auto
      paths:
        - /var/log/node-nibiru
      fields:
        host: $(wget -qO- eth0.me)
        name: nibiru
      encoding: plain" >> /etc/filebeat/filebeat.yml
  systemctl restart filebeat

  sed -i 's|^log_format *=.*|log_format = "json"|' $HOME/.nibid/config/config.toml
fi

if test -f "$DEFUND_DIR"; then
    echo "- type: http
      name: Defund-node
      hosts: ['http://$(wget -qO- eth0.me):32657']
      schedule: '@every 60s'
      timeout: 1s
      wait: 1s
      ssl:
        verification_mode: none
      tags: ["Defund"]" >> /etc/heartbeat/heartbeat.yml
    systemctl restart heartbeat

    echo "  - type: log
        format: auto
        paths:
          - /var/log/node-defund
        fields:
          host: $(wget -qO- eth0.me)
          name: defund
        encoding: plain" >> /etc/filebeat/filebeat.yml
    systemctl restart filebeat

    sed -i 's|^log_format *=.*|log_format = "json"|' $HOME/.defund/config/config.toml


fi

if test -f "$CASCADIA_DIR"; then
  echo "- type: http
    name: Cascadia-node
    hosts: ['http://$(wget -qO- eth0.me):28657']
    schedule: '@every 60s'
    timeout: 1s
    wait: 1s
    ssl:
      verification_mode: none
    tags: ["Cascadia"]" >> /etc/heartbeat/heartbeat.yml
  systemctl restart heartbeat

  echo "  - type: log
      format: auto
      paths:
        - /var/log/node-cascadia
      fields:
        host: $(wget -qO- eth0.me)
        name: cascadia
      encoding: plain" >> /etc/filebeat/filebeat.yml
  systemctl restart filebeat

  sed -i 's|^log_format *=.*|log_format = "json"|' $HOME/.cascadiad/config/config.toml
fi

if test -f "$BABYLON_DIR"; then
  echo "- type: http
    name: Babylon-node
    hosts: ['http://$(wget -qO- eth0.me):31657']
    schedule: '@every 60s'
    timeout: 1s
    wait: 1s
    ssl:
      verification_mode: none
    tags: ["Babylon"]" >> /etc/heartbeat/heartbeat.yml
  systemctl restart heartbeat

  echo "  - type: log
      format: auto
      paths:
        - /var/log/node-babylon
      fields:
        host: $(wget -qO- eth0.me)
        name: babylon
      encoding: plain" >> /etc/filebeat/filebeat.yml
  systemctl restart filebeat

  sed -i 's|^log_format *=.*|log_format = "json"|' $HOME/.babylond/config/config.toml
fi

if test -f "$ANDROMEDA_DIR"; then
    echo "- type: http
      name: Andromeda-node
      hosts: ['http://$(wget -qO- eth0.me):33657']
      schedule: '@every 60s'
      timeout: 1s
      wait: 1s
      ssl:
        verification_mode: none
      tags: ["Andromeda"]" >> /etc/heartbeat/heartbeat.yml
    systemctl restart heartbeat

    echo "  - type: log
        format: auto
        paths:
          - /var/log/node-andromeda
        fields:
          host: $(wget -qO- eth0.me)
          name: andromeda
        encoding: plain" >> /etc/filebeat/filebeat.yml
    systemctl restart filebeat

    sed -i 's|^log_format *=.*|log_format = "json"|' $HOME/.andromedad/config/config.toml

fi

if test -f "$OJO_DIR"; then
  echo "- type: http
    name: Ojo-node
    hosts: ['http://$(wget -qO- eth0.me):34657']
    schedule: '@every 60s'
    timeout: 1s
    wait: 1s
    ssl:
      verification_mode: none
    tags: ["Ojo"]" >> /etc/heartbeat/heartbeat.yml
  systemctl restart heartbeat

  echo "  - type: log
      format: auto
      paths:
        - /var/log/node-ojo
      fields:
        host: $(wget -qO- eth0.me)
        name: ojo
      encoding: plain" >> /etc/filebeat/filebeat.yml
  systemctl restart filebeat

  sed -i 's|^log_format *=.*|log_format = "json"|' $HOME/.ojod/config/config.toml
fi

if test -f "$SHARD_NODE"; then
    echo "- type: http
        name: Shardeum-node
        hosts: ['http://$(wget -qO- eth0.me):8080']
        schedule: '@every 60s'
        timeout: 1s
        wait: 1s
        ssl:
          verification_mode: none
        tags: ["Shardeum"]" >> /etc/heartbeat/heartbeat.yml

fi

if test -f "$MUON_NODE"; then
    echo "- type: http
            name: Muon-node
            hosts: ['http://$(wget -qO- eth0.me):8000/status']
            ipv4: true
            mode: any
            timeout: 1s
            wait: 1s
            tags: ["Muon"]" >> /etc/heartbeat/heartbeat.yml

fi
