#bin/bash!

echo -e "\033[0;33m Update Heartbeat config\033[0m"

echo "- type: http
  name: Namada-node
  hosts: ['$(wget -qO- eth0.me):26657']
  schedule: '@every 60s'
  timeout: 1s
  wait: 1s
  ssl:
    verification_mode: none
  tags: ["Namada"]" >> /etc/heartbeat/heartbeat.yml
systemctl restart heartbeat


echo -e "\033[0;33m Update Filebeat config\033[0m"
echo "  - type: log
    format: auto
    paths:
      - /var/log/node-namada
    fields:
      host: $HOSTNAME
      name: namada
    encoding: plain" >> /etc/filebeat/filebeat.yml
    
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service namadad status | grep active` =~ "running" ]]; then
	  echo -e "Your namada node \e[32minstalled and works\e[39m!"
	    echo -e "You can check node status by the command \e[7mservice namadad status\e[0m"
	      echo -e "Press \e[7mQ\e[0m for exit from status menu"
      else
	        echo -e "Your namada node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
