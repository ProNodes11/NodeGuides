#!/bin/bash

cd $HOME
 
wget https://github.com/massalabs/massa/releases/download/TEST.23.2/massa_TEST.23.2_release_linux.tar.gz 
 
tar zxvf massa_TEST.23.2_release_linux.tar.gz 
 
sudo systemctl stop massad && sudo systemctl start massad && sudo journalctl -f -n 100 -u massad 
