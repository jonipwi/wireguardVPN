#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
. "${SCRIPT_DIR}/utils.sh"

load_env "${ROOT_DIR}/config.env"

mkdir -p "${ROOT_DIR}/keys" "${ROOT_DIR}/runtime"
chmod 700 "${ROOT_DIR}/keys"

EXTERNAL_INTERFACE=$(detect_external_interface)
export EXTERNAL_INTERFACE

if [ ! -f "${ROOT_DIR}/keys/server_private.key" ]; then
  echo "[+] Generating server keys..."
  umask 077
  wg genkey | tee "${ROOT_DIR}/keys/server_private.key" | wg pubkey > "${ROOT_DIR}/keys/server_public.key"
fi

export SERVER_PRIVATE_KEY=$(cat "${ROOT_DIR}/keys/server_private.key")
export SERVER_PUBLIC_KEY=$(cat "${ROOT_DIR}/keys/server_public.key")

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
export WG_MTU_LINE EXTRA_POST_UP_LINES EXTRA_POST_DOWN_LINES

echo "[+] Rendering wg0.conf from template..."
export WG_ADDRESS WG_PORT WG_MTU EXTRA_POST_UP EXTRA_POST_DOWN
envsubst < "${ROOT_DIR}/templates/server.conf.tpl" > "${ROOT_DIR}/runtime/wg0.conf"

echo "[+] Installing wg0.conf to /etc/wireguard and starting service..."
sudo mkdir -p /etc/wireguard
sudo cp "${ROOT_DIR}/runtime/wg0.conf" /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0 || true
sudo systemctl restart wg-quick@wg0 || sudo wg-quick up wg0

echo "[+] Done. Server public key: ${SERVER_PUBLIC_KEY}"
