#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
. "${SCRIPT_DIR}/utils.sh"

load_env "${ROOT_DIR}/config.env"
EXTERNAL_INTERFACE=$(detect_external_interface)

# Load server keys
SERVER_PRIVATE_KEY=$(cat "${ROOT_DIR}/keys/server_private.key")
SERVER_PUBLIC_KEY=$(cat "${ROOT_DIR}/keys/server_public.key")

# Prepare optional lines for template
if [ -n "${WG_MTU:-}" ]; then WG_MTU_LINE="MTU=${WG_MTU}"; else WG_MTU_LINE=""; fi
EXTRA_POST_UP_LINES=""
if [ -n "${EXTRA_POST_UP:-}" ]; then
  IFS=';'
  read -ra cmds <<<"${EXTRA_POST_UP}"
  for c in "${cmds[@]}"; do
    [ -z "$c" ] && continue
    EXTRA_POST_UP_LINES+=$'PostUp='"$c"$'\n'
  done
fi
EXTRA_POST_DOWN_LINES=""
if [ -n "${EXTRA_POST_DOWN:-}" ]; then
  IFS=';'
  read -ra cmds <<<"${EXTRA_POST_DOWN}"
  for c in "${cmds[@]}"; do
    [ -z "$c" ] && continue
    EXTRA_POST_DOWN_LINES+=$'PostDown='"$c"$'\n'
  done
fi

export EXTERNAL_INTERFACE WG_ADDRESS WG_PORT SERVER_PRIVATE_KEY SERVER_PUBLIC_KEY
export WG_MTU_LINE EXTRA_POST_UP_LINES EXTRA_POST_DOWN_LINES

echo "[+] Re-rendering server config..."
envsubst < "${ROOT_DIR}/templates/server.conf.tpl" > "${ROOT_DIR}/runtime/wg0.conf"

echo "[+] Installing wg0.conf and restarting..."
sudo cp "${ROOT_DIR}/runtime/wg0.conf" /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
sudo systemctl restart wg-quick@wg0

echo "[+] Re-applying peer sections (if any in /etc/wireguard/wg0.conf already)"
sudo wg addconf wg0 <(wg-quick strip wg0)
