Обновляем репозиторий: 
```
sudo apt update && sudo apt upgrade -y
```
И скачиваем файлы:
```
sudo apt-get install curl wget jq libpq-dev libssl-dev \
build-essential pkg-config openssl ocl-icd-opencl-dev \
libopencl-clang-dev libgomp1 -y
```
Качаем git:
```
sudo apt install git
```
Докачиваем пакеты snap (пишем Y и жмем Enter):
```
sudo apt install snapd
```

Устанавливаем докер (можно вставлять как одну команду):
```
cd
apt update && apt purge docker docker-engine docker.io containerd docker-compose -y
rm /usr/bin/docker-compose /usr/local/bin/docker-compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
Устанавливаем docker compose (можно вставлять как одну команду):
```
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
Скачиваем rust и cargo. Вводите команду ниже, затем команда спросит, какую установку вы желаете выбрать, нажимайте 1 и Enter:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Меняем его расположение:
```
source $HOME/.cargo/env
```
И проверяем версию:
```
cargo --version
```
V1.62

Скачиваем nvm:
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```
Скачиваем NodeJS 16 версии (должно будет вывести версию 16 и еще какие-то цифры, они нас не интересуют) одной командой:
```
curl -s https://deb.nodesource.com/setup_16.x | sudo bash && \
sudo apt install nodejs -y && \
node -v
```
Переходим к установке ноды

Переходим в домашнюю директорию командой:
```
cd
```
Клонируем репозиторий бандлера командой:
```
git clone --recurse-submodules https://github.com/Bundlr-Network/validator-rust.git
cd validator-rust
```

Дальше нам понадобится кошелек Arweave, делаем его такой командой:
```
cargo run --bin wallet-tool create > wallet.json
```
ОБЯЗАТЕЛЬНО сохраняем файл wallet.json (делаем БЭКАП).
По пути: /root/validator-rust/



ОБЯЗАТЕЛЬНО переходим по пути: 
```
cd validator-rust
```

Смотрим адрес кошелька:
```
cargo run --bin wallet-tool show-address --wallet wallet.json
```
В самом низу, в поле address, будет адрес вашего кошелька.


Можете сохранить этот адрес для удобства.

Копируйте свой адрес кошелька и перейдите на faucet

Вставьте скопированный вами кошелек.


Сделайте ретвит к себе в твиттер.


Перейдите по вашему ретвиту и скопируйте ссылку.


Вставьте ссылку.

Возвращаемся в нашу консоль

Создаем файл .env (вставлять как одну команду):
```
tee $HOME/validator-rust/.env > /dev/null <<EOF
PORT=80
BUNDLER_URL="https://testnet1.bundlr.network"
GW_CONTRACT="RkinCLBlY4L5GZFv8gCFcrygTyd5Xm91CzKlR6qxhKA"
GW_ARWEAVE="https://arweave.testnet1.bundlr.network"
EOF
```
Запускаем докер командами ниже:
```
cd validator-rust
```
Если вы уже в папке validator-rust, то вам выдаст ошибку, не обращайте внимания

Запускаем билд:
```
docker-compose up -d
```
Теперь ничего нажимать не нужно, начался билд и он может продлиться достаточно долго вплоть до 20-30 минут, зависит от вашего сервера. 

Вы можете видеть много warning, это нормально.



Логи смотрим так:
```
docker-compose logs --tail=100 -f
```

Теперь нужно добавить своего валидатора на сайт тестнета.
В консоли пишем:
```
npm i -g @bundlr-network/testnet-cli
```

Дальше у нас длинная команда НО перед тем как ее вставить узнайте: ВАШ_АЙПИ_АДРЕС
```
npx @bundlr-network/testnet-cli@latest join RkinCLBlY4L5GZFv8gCFcrygTyd5Xm91CzKlR6qxhKA -w wallet.json -u http://ВАШ_АЙПИ_АДРЕС:8080/ -s 25000000000000
```
Чтобы узнать IP вашей ноды: либо гляньте его на вашем сервисе (например, хецнер),  либо введите команду:
```
ip a
```
Будет много айпи адресов НО они все пронумерованны 1, 2, 3 ,4 ... 
Ваш айпи адрес будет под цифрой 2. Скопируйте его и вставьте в команду выше вместо ВАШ_АЙПИ_АДРЕС.

В случае успешного создания валидатора вы увидите сообщение:
Done

Так же ваш валидатор должен будет отразиться в эксплорере.


Как только вы создали своего валидатора, вы закончили установку.

Напоминаю, что логи своей ноды мы можем смотреть вот так:
```
docker-compose logs -f --tail 100
```
