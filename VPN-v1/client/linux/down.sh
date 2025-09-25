#!/usr/bin/env bash
set -euo pipefail

# Bring down a WireGuard client connection

CONF_PATH="${1:-client.conf}"
NAME=$(basename "$CONF_PATH" .conf)

if [ ! -f "/etc/wireguard/${NAME}.conf" ]; then
  echo "Not found: /etc/wireguard/${NAME}.conf" >&2
  echo "Available configs:" >&2
  ls -1 /etc/wireguard/*.conf 2>/dev/null | sed 's|/etc/wireguard/||g; s|\.conf||g' | sed 's/^/  /' || echo "  (none)"
  exit 1
fi

sudo wg-quick down "$NAME"
echo "[+] VPN down: $NAME"