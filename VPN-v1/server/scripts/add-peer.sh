#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <peer-name> [peer-ip]" >&2
  exit 1
fi

PEER_NAME="$1"
REQUESTED_IP="${2:-}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)
. "${SCRIPT_DIR}/utils.sh"

load_env "${ROOT_DIR}/config.env"

EXTERNAL_INTERFACE=$(detect_external_interface)
export EXTERNAL_INTERFACE
export WG_MTU DNS CLIENT_ALLOWED_IPS SERVER_HOST WG_PORT PERSISTENT_KEEPALIVE

mkdir -p "${ROOT_DIR}/peers/${PEER_NAME}"
umask 077

echo "[+] Generating keys for ${PEER_NAME}..."
wg genkey | tee "${ROOT_DIR}/peers/${PEER_NAME}/${PEER_NAME}.key" | wg pubkey > "${ROOT_DIR}/peers/${PEER_NAME}/${PEER_NAME}.pub"
CLIENT_PRIVATE_KEY=$(cat "${ROOT_DIR}/peers/${PEER_NAME}/${PEER_NAME}.key")
CLIENT_PUBLIC_KEY=$(cat "${ROOT_DIR}/peers/${PEER_NAME}/${PEER_NAME}.pub")

SERVER_PUBLIC_KEY=$(cat "${ROOT_DIR}/keys/server_public.key")
SERVER_PRIVATE_KEY=$(cat "${ROOT_DIR}/keys/server_private.key")
export SERVER_PUBLIC_KEY SERVER_PRIVATE_KEY

PEERS_DIR="${ROOT_DIR}/peers"
if [ -z "$REQUESTED_IP" ]; then
  CLIENT_ADDRESS=$(alloc_next_ip "${PEER_START_IP}" "$PEERS_DIR")
else
  CLIENT_ADDRESS="$REQUESTED_IP"
fi

echo "CLIENT_ADDRESS=${CLIENT_ADDRESS}" > "${ROOT_DIR}/peers/${PEER_NAME}/meta.env"

if [ -n "${WG_MTU:-}" ]; then WG_MTU_LINE="MTU=${WG_MTU}"; else WG_MTU_LINE=""; fi
export CLIENT_PRIVATE_KEY CLIENT_ADDRESS WG_MTU_LINE

CLIENT_CONF_PATH="${ROOT_DIR}/peers/${PEER_NAME}/${PEER_NAME}.conf"
envsubst < "${ROOT_DIR}/templates/client.conf.tpl" > "$CLIENT_CONF_PATH"
chmod 600 "$CLIENT_CONF_PATH"

echo "[+] Adding peer to running interface and config..."
PEER_ALLOWED_IP="${CLIENT_ADDRESS}/32"
sudo wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$PEER_ALLOWED_IP"
echo -e "\n[Peer]\nPublicKey=${CLIENT_PUBLIC_KEY}\nAllowedIPs=${PEER_ALLOWED_IP}\n" | sudo tee -a /etc/wireguard/wg0.conf >/dev/null

echo "[+] Peer added: ${PEER_NAME} (${CLIENT_ADDRESS})"
echo "Client config: ${CLIENT_CONF_PATH}"
