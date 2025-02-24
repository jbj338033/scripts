#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

apt update
apt install -y openssh-server

systemctl start ssh
systemctl enable ssh

if command -v ufw &> /dev/null; then
    ufw allow ssh
    ufw --force enable
fi

SSH_DIR="/root/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ -f "$KEY_FILE" ]; then
    echo "SSH key already exists. Skipping key generation."
else
    ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N ""
    cat "$KEY_FILE.pub" >> "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"
fi

cat "$KEY_FILE"
