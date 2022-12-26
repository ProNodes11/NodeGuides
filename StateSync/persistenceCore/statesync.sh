#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

sudo apt install jq
sudo systemctl stop persistenceCore 
SNAP_RPC="http://persistence-api.stakeme.io:26657"
SNAP_RPC2="http://persistence-api.stakeme.io:26657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC2\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.persistenceCore/config/config.toml
persistenceCore tendermint unsafe-reset-all --home $HOME/.persistenceCore
sudo systemctl restart persistenceCore && sudo journalctl -fu persistenceCore -o cat
