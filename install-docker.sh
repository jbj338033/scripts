#!/bin/bash

set -eo pipefail

check_root() {
    [ "$(id -u)" != "0" ] && echo "Run with sudo" && exit 1
}

check_system() {
    command -v apt-get >/dev/null 2>&1 || { echo "Ubuntu/Debian only"; exit 1; }
}

get_user() {
    [ -n "${SUDO_USER}" ] && echo "${SUDO_USER}" || echo "${USER}"
}

setup_docker() {
    apt-get remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1 || true
    apt-get update -qq
    apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common >/dev/null 2>&1
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg >/dev/null 2>&1
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1
}

configure_docker() {
    local DOCKER_USER=$(get_user)
    local DOCKER_SOCK="/var/run/docker.sock"
    
    systemctl start docker >/dev/null 2>&1
    systemctl enable docker >/dev/null 2>&1

    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 64000,
            "Soft": 64000
        }
    }
}
EOF

    usermod -aG docker "${DOCKER_USER}" >/dev/null 2>&1
    [ -f "${DOCKER_SOCK}" ] && chown root:docker "${DOCKER_SOCK}" && chmod 666 "${DOCKER_SOCK}"
    systemctl daemon-reload >/dev/null 2>&1
    systemctl restart docker >/dev/null 2>&1
}

verify_installation() {
    docker version >/dev/null 2>&1 || { echo "Installation failed"; exit 1; }
    echo "Successfully installed"
}

main() {
    check_root
    check_system
    setup_docker
    configure_docker
    verify_installation
}

main