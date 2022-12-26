
# StateSync for PersistenceCore
## API
http://persistence-api.stakeme.io:26657/
## RPC
http://persistence-api.stakeme.io:1317

## Автоматическая синхронизация
```
wget https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/StateSync/persistenceCore/statesync.sh && chmod 700 statesync.sh && ./statesync.sh
```

## Ручная синхронизация
Для работы необходимо установить jq
```
sudo apt install jq
```
Останавливаем ноду
```
sudo systemctl stop persistenceCore 
```
Задаем RPC сервер Stakeme
```
SNAP_RPC="http://persistence-api.stakeme.io:26657"
SNAP_RPC2="http://persistence-api.stakeme.io:26657"
```
Получаем последнюю высоту, блок и хеш
```
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
```
Проверям полученые данные командой
```
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
```
Вывод должен быть похож на это
```
6152533 6151533 1B7B89F7C000E7CD5D6D357F74CBFB3784D55F0D63ADC521E124A823A728240A
```
Прописываем полученые данные командой в конфиг
```
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC2\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.persistenceCore/config/config.toml \
```
Ресетим ноду
```
persistenceCore tendermint unsafe-reset-all --home $HOME/.persistenceCore
```
Запускаем ноду и смотрим логи, нода должна синхронизироватся за минут 10
```
sudo systemctl restart persistenceCore && sudo journalctl -fu persistenceCore -o cat
```
