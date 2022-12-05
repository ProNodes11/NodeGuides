
# StateSync for Bitcanna

## Автоматическая синхронизация
```
wget https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/StateSync/bitcanna/statesync.sh && chmod 700 statesync.sh && ./statesync.sh
```

## Ручная синхронизация
Для работы необходимо установить jq
```
sudo apt install jq
```
Останавливаем ноду
```
sudo systemctl stop bcnad 
```
Задаем пир адрес
```
peers="3f9e2b5b27b5ca47a2f29df83cc1afdd5640d6da@216.238.73.231:26656"
sed -i.bak -e  "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.defund/config/config.toml
```
Задаем RPC сервер ProNodes
```
SNAP_RPC="216.238.73.231:26657"
SNAP_RPC2="216.238.73.231:26657"
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
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.bcna/config/config.toml \
```
Ресетим ноду
```
bcnad tendermint unsafe-reset-all --home $HOME/.bcna
```
Запускаем ноду и смотрим логи, нода должна синхронизироватся за минут 10
```
sudo systemctl restart bcnad && sudo journalctl -fu bcnad -o cat
```
