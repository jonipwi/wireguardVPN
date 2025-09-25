#!/usr/bin/env bash
set -euo pipefail

# Test script to validate WireGuard installation and config

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)

echo "[+] WireGuard VPN Project - Validation Test"

# Test 1: Check dependencies
echo "[1/7] Checking dependencies..."
for cmd in wg wg-quick iptables qrencode envsubst; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "  ❌ Missing: $cmd"
        exit 1
    else
        echo "  ✅ Found: $cmd"
    fi
done

# Test 2: Check config file
echo "[2/7] Checking config..."
if [ ! -f "${ROOT_DIR}/config.env" ]; then
    echo "  ❌ config.env not found"
    exit 1
fi

. "${SCRIPT_DIR}/utils.sh"
load_env "${ROOT_DIR}/config.env"

if [ -z "${SERVER_HOST:-}" ] || [ "${SERVER_HOST}" = "your.domain.example" ]; then
    echo "  ❌ SERVER_HOST not configured in config.env"
    exit 1
fi
echo "  ✅ Config valid: ${SERVER_HOST}"

# Test 3: Check server keys
echo "[3/7] Checking server keys..."
if [ ! -f "${ROOT_DIR}/keys/server_private.key" ] || [ ! -f "${ROOT_DIR}/keys/server_public.key" ]; then
    echo "  ❌ Server keys missing. Run generate-server.sh first"
    exit 1
fi
echo "  ✅ Server keys exist"

# Test 4: Check WireGuard service
echo "[4/7] Checking WireGuard service..."
if ! sudo systemctl is-active --quiet wg-quick@wg0; then
    echo "  ❌ wg-quick@wg0 service not running"
    exit 1
fi
echo "  ✅ WireGuard service active"

# Test 5: Check interface
echo "[5/7] Checking WireGuard interface..."
if ! sudo wg show wg0 >/dev/null 2>&1; then
    echo "  ❌ wg0 interface not found"
    exit 1
fi
echo "  ✅ wg0 interface exists"

# Test 6: Check IP forwarding
echo "[6/7] Checking IP forwarding..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ]; then
    echo "  ❌ IPv4 forwarding disabled"
    exit 1
fi
echo "  ✅ IPv4 forwarding enabled"

# Test 7: Check port accessibility
echo "[7/7] Checking port accessibility..."
EXTERNAL_INTERFACE=$(detect_external_interface)
if ! sudo ss -lun | grep -q ":${WG_PORT} "; then
    echo "  ❌ Port ${WG_PORT} not listening"
    exit 1
fi
echo "  ✅ Port ${WG_PORT} listening"

echo ""
echo "🎉 All tests passed! WireGuard server is ready."
echo ""
echo "Server info:"
echo "  Public key: $(cat "${ROOT_DIR}/keys/server_public.key")"
echo "  Endpoint: ${SERVER_HOST}:${WG_PORT}"
echo "  Network: ${WG_ADDRESS}"
echo ""
echo "Next: Add peers with ./add-peer.sh <name>"