#!/bin/bash

NIBIRU_DIR=/$HOME/.nibid/data/priv_validator_state.json
DEFUND_DIR=/$HOME/.defund/data/priv_validator_state.json
CASCADIA_DIR=/$HOME/.cascadiad/data/priv_validator_state.json
NOLUS_DIR=/$HOME/.nolus/data/priv_validator_state.json
BABYLON_DIR=/$HOME/.babylond/data/priv_validator_state.json
ANDROMEDA_DIR=/$HOME/.andromedad/data/priv_validator_state.json
OJO_DIR=/$HOME/.ojo/data/priv_validator_state.json

if test -f "$NIBIRU_DIR"; then
  systemctl stop nibid
  mv .nibid/data/priv_validator_state.json $HOME
  rm -rf .nibid/data/*
  mv priv_validator_state.json .nibid/data
  curl -L https://snapshots.kjnodes.com/nibiru-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.nibid
  systemctl start nibid
  echo "Nidiru cleaned"
fi

if test -f "$DEFUND_DIR"; then
  systemctl stop defund
  mv .defund/data/priv_validator_state.json $HOME
  rm -rf .defund/data/*
  mv priv_validator_state.json .defund/data
  curl -L https://snapshots.kjnodes.com/defund-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.defund
  systemctl start defund
  echo "Defund cleaned"
fi

if test -f "$CASCADIA_DIR"; then
  systemctl stop cascadiad
  mv .cascadiad/data/priv_validator_state.json $HOME
  rm -rf .cascadiad/data/*
  mv priv_validator_state.json .cascadiad/data
  curl -L https://snapshots.kjnodes.com/cascadia-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.cascadiad
  systemctl start cascadiad
  echo "Cascadia cleaned"
fi

if test -f "$NOLUS_DIR"; then
  systemctl stop nolus
  mv .nolus/data/priv_validator_state.json $HOME
  rm -rf .nolus/data/*
  mv priv_validator_state.json .nolus/data
  
  systemctl start nolus
  echo "Nolus cleaned"
fi

if test -f "$BABYLON_DIR"; then
  systemctl stop babylond
  mv .babylond/data/priv_validator_state.json $HOME
  rm -rf .babylond/data/*
  mv priv_validator_state.json .babylond/data
  URL="https://snapshots-testnet.r1m-team.com/babylon/bbn-test1_latest.tar.lz4"
  curl -L $URL | tar -Ilz4 -xf - -C $HOME/.babylond
  systemctl start babylond
  echo "Babylon cleaned"
fi

if test -f "$ANDROMEDA_DIR"; then
  systemctl stop andromedad
  mv .andromedad/data/priv_validator_state.json $HOME
  rm -rf .andromedad/data/*
  mv priv_validator_state.json .andromedad/data
  curl -L https://snapshots.kjnodes.com/andromeda-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.andromedad
  systemctl start andromedad
  echo "Andromeda cleaned"
fi

if test -f "$OJO_DIR"; then
  systemctl stop ojod
  mv .ojo/data/priv_validator_state.json $HOME
  rm -rf .ojo/data/*
  mv priv_validator_state.json .ojo/data
  curl -L https://snapshots.kjnodes.com/ojo-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.ojo
  systemctl start ojod
  echo "Ojo cleaned"
fi
