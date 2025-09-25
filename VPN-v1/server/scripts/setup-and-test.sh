#!/usr/bin/env bash
set -euo pipefail

# Quick setup and test script for WireGuard project
# This validates the installation and creates a test peer

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)

echo "[+] WireGuard VPN Project - Quick Setup & Test"
echo "    Root: ${ROOT_DIR}"

# Check if running as root/sudo
if [[ $EUID -eq 0 ]]; then
   echo "Don't run this script as root. It will call sudo when needed." >&2
   exit 1
fi

# Check OS
if ! grep -q "ubuntu\|debian" /etc/os-release 2>/dev/null; then
    echo "Warning: This script is tested on Ubuntu/Debian. Proceed with caution."
fi

# Check config exists
if [ ! -f "${ROOT_DIR}/config.env" ]; then
    echo "Error: ${ROOT_DIR}/config.env not found. Please configure it first." >&2
    echo "See README.md for setup instructions." >&2
    exit 1
fi

# Load config
. "${ROOT_DIR}/scripts/utils.sh"
load_env "${ROOT_DIR}/config.env"

# Validate required config
if [ -z "${SERVER_HOST:-}" ] || [ "${SERVER_HOST}" = "your.domain.example" ]; then
    echo "Error: Please set SERVER_HOST in config.env to your domain or public IP" >&2
    exit 1
fi

echo "[+] Config validation passed"
echo "    Server: ${SERVER_HOST}:${WG_PORT}"
echo "    Network: ${WG_ADDRESS}"

# Run installation if not done
echo "[+] Running installation script..."
"${ROOT_DIR}/scripts/install.sh"

# Generate server if not done
if [ ! -f "${ROOT_DIR}/keys/server_private.key" ]; then
    echo "[+] Generating server keys and config..."
    "${ROOT_DIR}/scripts/generate-server.sh"
else
    echo "[+] Server keys exist, skipping generation"
fi

# Check if WireGuard is running
if ! sudo systemctl is-active --quiet wg-quick@wg0; then
    echo "[+] Starting WireGuard service..."
    sudo systemctl start wg-quick@wg0
fi

# Check status
echo "[+] WireGuard status:"
sudo wg show

# Create a test peer
TEST_PEER="test-$(date +%s)"
echo "[+] Creating test peer: ${TEST_PEER}"
"${ROOT_DIR}/scripts/add-peer.sh" "${TEST_PEER}"

# Show QR for the test peer
echo "[+] QR code for ${TEST_PEER}:"
"${ROOT_DIR}/scripts/show-qr.sh" "${ROOT_DIR}/peers/${TEST_PEER}/${TEST_PEER}.conf"

echo ""
echo "[+] Setup complete! Next steps:"
echo "    1. Client config: ${ROOT_DIR}/peers/${TEST_PEER}/${TEST_PEER}.conf"
echo "    2. Use scripts/show-qr.sh for mobile QR codes"
echo "    3. Use scripts/add-peer.sh <name> to add more peers"
echo "    4. Use scripts/list-peers.sh to see connected peers"
echo ""
echo "    Don't forget to open UDP port ${WG_PORT} in your firewall!"