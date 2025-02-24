#!/bin/bash

sudo apt update
sudo apt install -y openssh-server

sudo systemctl start ssh
sudo systemctl enable ssh

sudo ufw allow ssh
sudo ufw --force enable

sudo mkdir -p ~/.ssh
sudo chmod 700 ~/.ssh

sudo ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
sudo cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sudo chmod 600 ~/.ssh/authorized_keys
sudo chown -R ubuntu:ubuntu ~/.ssh

cat ~/.ssh/id_rsa