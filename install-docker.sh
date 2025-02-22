#!/bin/bash

apt-get remove -y docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://get.docker.com | sh

systemctl start docker
systemctl enable docker

usermod -aG docker $USER
newgrp docker

exit 0
