#!/bin/bash

cd /root 
 
wget https://github.com/massalabs/massa/releases/download/TEST.22.1/massa_TEST.22.1_release_linux.tar.gz 
 
tar zxvf massa_TEST.22.1_release_linux.tar.gz 
 
sudo systemctl stop massad && sudo systemctl start massad && sudo journalctl -f -n 100 -u massad 