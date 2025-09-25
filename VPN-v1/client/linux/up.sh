#!/usr/bin/env bash
set -euo pipefail

CONF_PATH="${1:-client.conf}"
NAME=$(basename "$CONF_PATH" .conf)

if [ ! -f "$CONF_PATH" ]; then
  echo "Not found: $CONF_PATH" >&2
  exit 1
fi

sudo cp "$CONF_PATH" "/etc/wireguard/${NAME}.conf"
sudo chmod 600 "/etc/wireguard/${NAME}.conf"
sudo wg-quick down "$NAME" 2>/dev/null || true
sudo wg-quick up "$NAME"

echo "[+] VPN up: $NAME"
