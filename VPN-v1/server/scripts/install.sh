#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)

echo "[+] Installing WireGuard and utilities..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y wireguard qrencode iproute2 iptables gettext-base

echo "[+] Enabling IP forwarding..."
sudo sed -i 's/^#\?net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sed -i 's/^#\?net.ipv6.conf.all.forwarding=.*/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf || true
sudo sysctl -p || true

echo "[+] Creating directories and permissions..."
mkdir -p "${ROOT_DIR}/keys" "${ROOT_DIR}/peers" "${ROOT_DIR}/logs" "${ROOT_DIR}/runtime"
chmod 700 "${ROOT_DIR}/keys" "${ROOT_DIR}/peers"
touch "${ROOT_DIR}/peers/.gitkeep"

echo "[+] Done. Next: configure ${ROOT_DIR}/config.env and run generate-server.sh"
