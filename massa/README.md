# Установка
Обновляем пакеты
```
sudo apt update && sudo apt upgrade -y
```
Устанавливаем необходимые пакеты
```
sudo apt install wget jq git build-essential pkg-config libssl-dev -y
```
Скачиваем массу
```
massa_version=`wget -qO- https://api.github.com/repos/massalabs/massa/releases/latest | jq -r ".tag_name"`; \ wget -qO $HOME/massa.tar.gz "https://github.com/massalabs/massa/releases/download/${massa_version}/massa_${massa_version}_release_linux.tar.gz"; \ tar -xvf $HOME/massa.tar.gz; \ rm -rf $HOME/massa.tar.gz
```
Делаем бинарные файлы исполняемыми
```
chmod +x $HOME/massa/massa-node/massa-node \ $HOME/massa/massa-client/massa-client
```
Добавляем пароль в переменные 
```
sed -i "/ massa_password=/d" $HOME/.bash_profile echo 'export massa_password="ВВЕСТИ_ПАРОЛЬ"' >> $HOME/.bash_profile . $HOME/.bash_profile
```
Добавляем команды в систему в виде переменных
```
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/Massa/main/insert_variables.sh)
```
Создаем сервисный файл
```
sudo tee <<EOF >/dev/null /etc/systemd/system/massad.service 
[Unit] 
Description=Massa Node 
After=network-online.target 

[Service] 
User=$USER 
WorkingDirectory=$HOME/massa/massa-node 
ExecStart=$HOME/massa/massa-node/massa-node -p "$massa_password" 
Restart=on-failure 
RestartSec=3 
LimitNOFILE=65535 

[Install] 
WantedBy=multi-user.target 
EOF
```
Запускаем сервис
```
sudo systemctl daemon-reload 
sudo systemctl enable massad 
sudo systemctl restart massad
```
Получение токенов
Получаем токены в дискорде в канале testnet-faucet введя адрес кошелька полученый командой: massa_wallet_info

Стейкинг
⠀Для участия в тестовой сети необходимо купить как минимум 1 ROLL и застейкать его. Курс обмена: 1 ROLL = 100 MAS.

Покупаем роллы
```
massa_buy_rolls -mb
```
Включаем возможность стейкинга для кошелька
```
massa_cli_client -a node_add_staking_secret_keys
```
Через определенное время ролл станет активным и начнут капать токены

# Обновление
Обновится можно через скрипт
```
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/Massa/main/multi_tool.sh)
```
Он создаст копию нужных файлов и сохранит их по пути $HOME/massa_backup/
После обновления необходимо будет заново запросить токены и застейкать их.
