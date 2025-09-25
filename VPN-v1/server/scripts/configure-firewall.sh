#!/usr/bin/env bash
set -euo pipefail

# Firewall configuration helper for WireGuard server

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
. "${SCRIPT_DIR}/utils.sh"

load_env "${ROOT_DIR}/config.env"

echo "[+] Configuring firewall for WireGuard..."
echo "    Port: ${WG_PORT}/udp"

# UFW (Ubuntu default)
if command -v ufw >/dev/null 2>&1; then
    echo "[+] Configuring UFW..."
    sudo ufw allow "${WG_PORT}/udp" comment "WireGuard VPN"
    
    # Allow forwarding (if not already enabled)
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "[+] UFW is disabled. Enable it manually if desired: sudo ufw enable"
    else
        echo "[+] UFW rule added"
    fi
fi

# iptables direct (fallback)
if ! command -v ufw >/dev/null 2>&1; then
    echo "[+] Configuring iptables directly..."
    sudo iptables -I INPUT -p udp --dport "${WG_PORT}" -j ACCEPT
    echo "[+] iptables rule added (temporary - save with iptables-save if needed)"
fi

# systemd-networkd / firewalld (if present)
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "[+] Configuring firewalld..."
    sudo firewall-cmd --permanent --add-port="${WG_PORT}/udp"
    sudo firewall-cmd --reload
    echo "[+] firewalld rule added"
fi

echo "[+] Firewall configuration complete"
echo "    Note: Cloud providers (AWS, GCP, etc.) may require additional security group rules"