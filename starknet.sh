#!/bin/bash

curl -s https://raw.githubusercontent.com/ProNodes11/NodeGuides/main/logo | bash

read -p "Enter moniker for node: " ALCHEMY_ENDPOINT

echo "export ALCHEMY_ENDPOINT=$ALCHEMY_ENDPOINT" >> $HOME/.bash_profile && \
source $HOME/.bash_profile
mkdir -p $HOME/pathfinder

docker run \
  --name pathfinder \
  --restart unless-stopped \
  --detach \
  -p 9545:9545 \
  --user "$(id -u):$(id -g)" \
  -e RUST_LOG=info \
  -e PATHFINDER_ETHEREUM_API_URL="$ALCHEMY_ENDPOINT" \
  -v $HOME/pathfinder:/usr/share/pathfinder/data \
  eqlabs/pathfinder
