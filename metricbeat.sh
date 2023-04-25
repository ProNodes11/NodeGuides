#!/bin/sh

curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.7.0-linux-x86_64.tar.gz
tar xzvf metricbeat-8.7.0-linux-x86_64.tar.gz
mv metricbeat-8.7.0-linux-x86_64 /etc/metricbeat
rm /etc/metricbeat/metricbeat.yml

sudo tee /etc/metricbeat/metricbeat.yml > /dev/null <<EOF
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression

setup.kibana:
    host: "65.109.130.250:5601"
    username: "elastic"
    password: "changeme"

output.elasticsearch:
  hosts: ["65.109.130.250:9200"]
  username: "elastic"
  password: "changeme"
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF

sudo tee /etc/systemd/system/metricbeat.service > /dev/null <<EOF
[Unit]
Description=metricbeat
After=network-online.target
[Service]
User=$USER
WorkingDirectory=/etc/metricbeat
ExecStart=/etc/metricbeat/metricbeat -e
RestartSec=10
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable metricbeat
systemctl start metricbeat
