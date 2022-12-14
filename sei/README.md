Сервер можно купить на сервисе hetzner (советую покупать dedicated server).
Такие сервера будут стоить дешевле чем облачные. Но нужно будет заплатить немного за сборку. Достаточно просто выбрать сервер, который будет подходить под характеристики выше (это официальные требования самого Sei)

Как только вы подключитесь к своему серверу и увидите командную строку (CLI), можете приступать к установке.

Все команды я выделял специальным текстом.

Обновляем репозиторий (то есть, обновляем все установленные пакеты на сервере, чтобы при работе с сервером не возникло проблем):
```
sudo apt update && sudo apt upgrade -y
```
Устанавливаем гитхаб (git) (когда вас попросит, то в командную строку нужно будет ввести Y и нажать Enter):
```
sudo apt-get install git-all
```

Чтобы проверить устанавился git или нет, проверим версию (напишет что-то вроде: git version 2.25.1). 

Команда для проверки:
```
git version
```
Установим jq:
```
apt-get install -y jq
```

Устанавливаем мета-пакет, следующая команда установит все необходимые инстурменты для ввода команд по типу -> make install (эта команда встретиться в моем гайде ниже).


Когда вас попросит, то в командную строку нужно будет ввести Y и нажать Enter.
```
sudo apt install build-essential
```

Устанавливаем Go (выделить все и вводить как одну команду):
```
ver="1.18.1" && \ 
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version
```
Клонируем репозиторий SEI:
```
git clone https://github.com/sei-protocol/sei-chain.git
```

Переходи в папку sei-chain:
```
cd sei-chain
```

Дальше смотри актуальную версию с их гитхаба ЛИНК.
В моем случае это 1.0.6beta.
```
git checkout ВАША_ВЕРСИЯ
```

Если вам выдаст длинный текст - не обращаем внимание, в конце будет написано примерно так: HEAD is now at e3958ff Add 1.0.6beta upgrade handler Значит, все ок.

Устанавливаем пакеты

Если вы уже в папке sei-chain, вам выдаст эррор в случае ввода команды cd sei-chain, это нормально, если эррора нет, значит вы просто перешли в нужную папку и у вас тоже все нормально, вводим команды по очереди (только коричневый блок):
```
cd sei-chain/
make install
seid version --long | head
```
После команд выше, вы должны увидеть что-то такое:
name: sei server_name: <appd> version: 1.0.6beta
Придумайте название своей ноды и введите в кавычках (Моникер):
```
export MONIKER="Ваше_имя_ноды"
```

ОБЯЗАТЕЛЬНО ЗАПОМНИТЕ ИЛИ ЗАПИШИТЕ ЕГО, вам понадобится моникер в конце для создания валидатора.

Инициализируем нашу ноду (должно вывести много текста, значит все норм):
```
seid init $MONIKER --chain-id atlantic-1 -o
```

Скачиваем addrbook и genesis файлы, две отдельные команды ниже:

В файле Genesis указываются остатки на счетах и параметры на начало работы сети для использования при воспроизведении транзакций и синхронизации.
Адресная книга содержит список пиров, с которыми ваш узел может связаться, чтобы обнаружить другие узлы в сети.
```
curl https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-incentivized-testnet/genesis.json > ~/.sei/config/genesis.json

curl https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-incentivized-testnet/addrbook.json > ~/.sei/config/addrbook.json
```
Добавляем пиры (данные команды изменят некоторые данные в файлах для корректной работы ноды):
```
seeds=""
peers="e3b5da4caea7370cd85d7738eedaec8f56c5be28@144.76.224.246:36656,a37d65086e78865929ccb7388146fb93664223f7@18.144.13.149:26656,8ff4bd654d7b892f33af5a30ada7d8239d6f467b@91.223.3.190:51656,c4e8c9b1005fe6459a922f232dd9988f93c71222@65.108.227.133:26656";\
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.sei/config/config.toml
```
Также, если используете инструмент MobaXTerm то сможете перейти по данному пути:

/root/.sei/config/
Откройте файл config.toml в текстовом редакторе, по дефолту в MobaXterm есть редактор MobaRte, можете открыть в нем:


Два файла в которых мы проведем некоторые изменения
И с помощью поиска Ctrl + F  впишите в поиск : persistent_peers

В одном из найденных значений у вас должно быть то, что вы вводили выше, то есть:


persistent_peers = "e3b5da4caea7370cd85d7738eedaec8f56c5be28@144.76.224.246:36656,a37d65086e78865929ccb7388146fb93664223f7@18.144.13.149:26656,8ff4bd654d7b892f33af5a30ada7d8239d6f467b@91.223.3.190:51656,c4e8c9b1005fe6459a922f232dd9988f93c71222@65.108.227.133:26656"
Если что-то не так, поменяйте значение руками и сохраните файл, чтобы в persistent_peers было написано значение, как выше.

И так же, по желанию, вы можете изменить минимальную стоимость газа за транзакции в данной тестовой сети, команда ниже:
```
sed -i 's/minimum-gas-prices *=.*/minimum-gas-prices = "0.0025usei"/g' $HOME/.sei/config/app.toml
```
Так же ВАЖНО обновить конфиг для болле быстрой синхронизации ноды!

Обновляем командами ниже (вводить как одну команду):
```
wget -qO optimize-configs.sh https://raw.githubusercontent.com/sei-protocol/testnet/main/sei-testnet-2/optimize-configs.sh
sudo chmod +x optimize-configs.sh && ./optimize-configs.sh
sudo systemctl restart seid && sudo journalctl -u seid -f -o cat
```
ВАЖНО!
Обязательно нужно добавить сервисный файл, без него нода не будет работать.

Для этого вводим такую команду:
```
nano /etc/systemd/system/seid.service
```
Перед вами откроется пустой файлик, скопируйте выделенный текст ниже:
```
[Unit]
Description=Sei-Network Node
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/root/go/bin/seid start
Restart=on-failure
StartLimitInterval=0
RestartSec=3
LimitNOFILE=65535
LimitMEMLOCK=209715200

[Install]
WantedBy=multi-user.target
```
Теперь вставьте этот текст в файл, по дефолту вставка происходит нажатием по колесику мыши.
Нажимайте Ctrl+X.
Введите Y и нажмите Enter.

После этого вас должно выкинуть обратно в командную строку.

Теперь перейдите в папку:
```
cd sei-chain
```
Перезагружаем сервисный файл:
```
sudo systemctl daemon-reload
```
Включим seid.service:
```
sudo systemctl enable seid.service
```
Стартуем ноду и смотрим на наши логи командой ниже:
```
systemctl start seid && journalctl -u seid -f
```
Должно быть так:

Ждем синхронизации ноды с актуальной высотой, актуальная высота в ЭКСПЛОРЕРЕ

После создаем, либо востанавливаем кошелек, если вы первый раз ставите ноду, то создаете кошелек командой ниже (вместо ИМЯ_КОШЕЛЬКА напишете придуманное вами имя):
```
seid keys add ИМЯ_КОШЕЛЬКА
```
Придумайте пароль:


ПРИ ВСТАВКЕ ПАРОЛЯ ЕГО НЕ ВИДНО В ТЕРМИНАЛЕ

Поэтому сразу запишите его куда-то и копируйте оттуда в свой терминал

После того как пароль вставлен жмете Enter

И повторяете пароль еще раз снова жмете Enter
Ваш кошелек создан и должно быть вот такое сообщение:


Обязательно сохраните все эти данные И ЧТО САМОЕ ВАЖНОЕ ВАШ МНЕМОНИК!

Как видите в поле mnemonic "" пустота.
Но в самом низу где я замазал все черным будет ваш мнемоник адресс, вот его вам нужно скопировать и обязательно сохранить.


Заходим в дискорд SEI:
Переходим в канал.
Подтверждаем, что мы не робот и т.д.
Нам нужно перейти в канал atlantic-1-faucet.
Там вводим команду, чтобы получить тестовую монетку. 
ВАЖНО!

Обязательно замените кошелек на свой, который мы сделали выше! 
Команда для запроса токенов с фасета (кошелек меняем на свой):
```
!faucet sei19ldw08umfc0u0xe6000000000000000
```

После этого бот должен начислить вам тестовую монетку.

Теперь ждете полной синхронизации ноды!

То есть высота в ваших логах должна совпадать с высотой в explorer.

Логи смотрим так:
```
sudo journalctl -u seid -f -o cat
```
Как только значение height

совпадет со значением Block Height в explorer ЛИНК .


Напоминаю, что высота постоянно растет, так что актуальную высоту смотрим на сайте самостоятельно, линк дал выше.

ТЕПЕРЬ ТОЛЬКО КОГДА значение height совпадет со значением Block Height в эксплорер!

Только тогда переходим к созданию нашего валидатора, командой ниже, НО ОБЯЗАТЕЛЬНО ПРОЧТИТЕ ОПИСАНИЕ к этой команде (копировать все и вставлять одной коммандой):
```
seid tx staking create-validator \
--from ИМЯ_ВАШЕЙ_НОДЫ \
--chain-id atlantic-1 \
--moniker="ИМЯ_ВАШЕГО_КОШЕЛЬКА" \
--commission-max-change-rate=0.1 \
--commission-max-rate=0.2 \
--commission-rate=0.05 \
--pubkey $(seid tendermint show-validator) \
--min-self-delegation="1" \
--amount 1000000usei \
--fees 5550usei
```
ОПИСАНИЕ:

Вместо ИМЯ_ВАШЕЙ_НОДЫ ставим то имя которое вы придумали это ваш MONIKER, я просил записать или запомнить его.

Вместо ИМЯ_ВАШЕГО_КОШЕЛЬКА пишите то значение которое вы сами придумали, я тоже просил сохранить его.


Вот из значения name, копируете имя своего кошелька.


Теперь после полной синхронизации ноды вводите эту длинную комманду для создания валидатора, вас попросит указать ваш пароль, вводите его и жмете Enter.

Если все действия выполнены верно, то у вас появится текст вашей транзакции, в случае, если ваш валидатор успешно создан, вы не должны увидеть там никаких ошибок.

https://sei.explorers.guru/validators

Своего валидатора по вашему Moniker(Имя ноды) можете искать на этой страничке.

После этого обязательно перейдите по этому пути
/root/.sei/config/

И сохраните/ забекапьте файл priv_validator_key.json


На этом все! У вас создан валидатор и стоит нода:)

Полезные команды:

Чтобы проверить логи:
```
journalctl -u seid -f -o cat
```
Если видите какие-то ошибки в логах, можете перезагрузить вашу ноду и вывести логи командой ниже:
```
sudo systemctl restart seid && journalctl -u seid -f -o cat
```
