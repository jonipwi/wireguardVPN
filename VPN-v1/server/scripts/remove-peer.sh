#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <peer-name>" >&2
  exit 1
fi

PEER_NAME="$1"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)

if [ ! -d "${ROOT_DIR}/peers/${PEER_NAME}" ]; then
  echo "Peer not found: ${PEER_NAME}" >&2
  exit 1
fi

CLIENT_PUBLIC_KEY=$(cat "${ROOT_DIR}/peers/${PEER_NAME}/${PEER_NAME}.pub")

echo "[+] Removing peer from /etc/wireguard/wg0.conf..."
sudo awk -v key="$CLIENT_PUBLIC_KEY" '
  BEGIN{RS=""; ORS="\n\n"}
  !($0 ~ "\\[Peer\\][\n\r]+PublicKey="key)
' /etc/wireguard/wg0.conf | sudo tee /etc/wireguard/wg0.conf.new >/dev/null
sudo mv /etc/wireguard/wg0.conf.new /etc/wireguard/wg0.conf

echo "[+] Restarting wg-quick@wg0..."
sudo systemctl restart wg-quick@wg0

echo "[+] Deleting local peer files..."
rm -rf "${ROOT_DIR}/peers/${PEER_NAME}"

echo "[+] Peer removed: ${PEER_NAME}"
