#!/bin/bash

apt install -y openssh-server
systemctl start ssh
systemctl enable ssh

ufw allow ssh

mkdir -p ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
cat ~/.ssh/id_rsa