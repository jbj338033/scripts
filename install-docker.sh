#!/bin/bash

set -euo pipefail

DOCKER_SOCK="/var/run/docker.sock"
REQUIRED_PACKAGES=(
    apt-transport-https
    ca-certificates
    curl
    gnupg
    lsb-release
    software-properties-common
)

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

check_system() {
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "This script requires a Debian-based system" 1>&2
        exit 1
    fi

    if [ ! -f /etc/os-release ]; then
        echo "Cannot determine OS version" 1>&2
        exit 1
    fi
}

check_memory() {
    local min_memory=2048
    local available_memory=$(free -m | awk '/^Mem:/{print $2}')
    
    if [ "${available_memory}" -lt "${min_memory}" ]; then
        echo "Warning: System has less than 2GB RAM (${available_memory}MB)"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_disk_space() {
    local min_space=20
    local available_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    
    if [ "${available_space}" -lt "${min_space}" ]; then
        echo "Error: Insufficient disk space. At least ${min_space}GB required."
        exit 1
    fi
}

cleanup_old_docker() {
    echo "Removing old Docker installations..."
    apt-get remove -y docker docker-engine docker.io containerd runc || true
    apt-get autoremove -y
}

install_dependencies() {
    echo "Installing dependencies..."
    apt-get update && apt-get upgrade -y
    apt-get install -y "${REQUIRED_PACKAGES[@]}"
}

install_docker() {
    echo "Installing Docker..."
    if curl -fsSL https://get.docker.com -o get-docker.sh; then
        sh get-docker.sh
        rm get-docker.sh
    else
        echo "Failed to download Docker installation script"
        exit 1
    fi
}

configure_docker() {
    echo "Configuring Docker..."
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker
}

setup_permissions() {
    echo "Setting up Docker permissions..."
    if [ ! -f "${DOCKER_SOCK}" ]; then
        echo "Docker socket not found. Please check Docker installation."
        exit 1
    fi

    chmod 666 "${DOCKER_SOCK}"
    chown root:docker "${DOCKER_SOCK}"

    if [ -n "${SUDO_USER:-}" ]; then
        local REAL_USER="${SUDO_USER}"
    elif [ -n "${USER:-}" ]; then
        local REAL_USER="${USER}"
    else
        echo "Cannot determine the real user"
        exit 1
    fi

    usermod -aG docker "${REAL_USER}"
    echo "Added ${REAL_USER} to docker group"
}

verify_installation() {
    echo "Verifying Docker installation..."
    if ! docker version >/dev/null 2>&1; then
        echo "Docker installation verification failed"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo "Docker daemon is not running properly"
        exit 1
    }
}

create_docker_directories() {
    echo "Creating Docker directories..."
    mkdir -p /etc/docker
    mkdir -p /var/lib/docker
}

configure_docker_daemon() {
    echo "Configuring Docker daemon..."
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
}

main() {
    echo "Starting Docker installation..."
    
    check_root
    check_system
    check_memory
    check_disk_space
    
    cleanup_old_docker
    install_dependencies
    create_docker_directories
    install_docker
    configure_docker_daemon
    configure_docker
    setup_permissions
    verify_installation
    
    echo "Docker installation completed successfully"
    echo "Please log out and log back in for group changes to take effect"
}

main
exit 0