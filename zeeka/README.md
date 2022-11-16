# Установка необходимого ПО
Для роботы майнера необходимо установить драйвера для Nvidia и необходимые пакеты.
Команда для установки необходимого пакета:
```
apt install ocl-icd-opencl-dev
```
Установить драйвера можно с помощью этих команд:
```
sudo add-apt-repository ppa:graphics-drivers/ppa 
sudo apt update 
sudo apt install -y ubuntu-drivers-common 
sudo ubuntu-drivers autoinstall
```
Проверяем правильно ли установились драйвера командой:
```
nvidia-smi
```
# Устанавливаем майнер Zoro
Скачиваем майнер с репозитория
```
git clone https://github.com/zeeka-network/zoro 
cd zoro 
cargo install --path .
```
2. Скачиваем необходимые файлы для работы майнера
```
wget https://api.rues.info/payment_params.dat -O payment_params.dat wget https://api.rues.info/update_params.dat -O update_params.dat
```
3. Создаем сервис для майнера.

В параметре "node" указываем адрес вашей ноды. Если вы ставите майнер на сервер с нодой, то ничего не меняем. Если нода находиться в другом месте, то указываем ее адресс.

Вместо "seed phrase for the executor account" в скобках прописываем вашу сид фразу. Важно НЕ использовать такую же фразу как и в ноде, а придумать другую.

Следующими параметрами указываем путь к данным которые мы скачали шаг назад. Если вы действовали по нашему гайду, то они должны находиться по пути $HOME/.zoro/.

Параметр в конце —gpu определяет что майнер будет использовать вашу видюху для роботы, его можно убрать если вы имеете желание майнить на процессоре. Но тогда эффективность работы сильно упадет.
```
sudo tee <<EOF >/dev/null /etc/systemd/system/zorod.service 
[Unit] 
Description=Zoro node 
After=network.target

[Service]
 User=$USER 
ExecStart=/root/.cargo/bin/zoro --node 127.0.0.1:8765 --seed 'seed phrase for the executor account' --network chaos   --update-circuit-params  $HOME/.zoro/update_params.dat --payment-circuit-params  $HOME/.zoro/payment_params.dat   --db $HOME/.bazuka-chaos --gpu Restart=on-failure 
RestartSec=3 
LimitNOFILE=65535

[Install] 
WantedBy=multi-user.target 
EOF
```
Запускаем службу и добавляем ее в автозапуск
```
sudo systemctl daemon-reload
sudo systemctl enable zorod
sudo systemctl restart zorod
```
Проверить логи майнера можно командой
```
sudo journalctl -f -u zorod
```


# Установка Uzi-miner

После того как майнер Zoro установлен и запущен, он начинает генерировать блоки, которые необходимо решить. Этим занимается Uzi-miner.

1. Скачиваем Uzi:
```
cd git clone https://github.com/zeeka-network/uzi-miner 
cd uzi-miner 
cargo install --path .
```
2. Создаем службу:

В параметре --threads указываем количество потоков, которые будут использованы для работы(чем больше, тем лучше)
```
sudo tee <<EOF >/dev/null /etc/systemd/system/uzid.service 
[Unit]
 Description=Zoro node 
After=network.target

[Service] 
User=root 
ExecStart=/root/.cargo/bin/uzi-miner --node 127.0.0.1:8765 --threads 8 Restart=on-failure
 RestartSec=3 
LimitNOFILE=65535

[Install]
 WantedBy=multi-user.target 
EOF
```
3. Запускаем службу :
```
sudo systemctl daemon-reload 
sudo systemctl enable uzid 
sudo systemctl restart uzid
```
4. Проверяем логи:
```
sudo journalctl -f -u uzid
```
