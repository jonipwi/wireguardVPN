#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-client.conf>" >&2
  exit 1
fi

CONF="$1"
if [ ! -f "$CONF" ]; then
  echo "Not found: $CONF" >&2
  exit 1
fi

qrencode -t ansiutf8 < "$CONF"
