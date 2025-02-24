#!/bin/bash

apt update
apt install -y openssh-server

systemctl start ssh
systemctl enable ssh

ufw allow ssh
ufw --force enable

mkdir -p ~/.ssh
chmod 700 ~/.ssh

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R ubuntu:ubuntu ~/.ssh

cat ~/.ssh/id_rsa