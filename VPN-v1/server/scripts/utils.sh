#!/usr/bin/env bash
set -euo pipefail

# Load .env-like file into environment (only simple KEY=VALUE pairs)
load_env() {
  local env_file="$1"
  [ -f "$env_file" ] || { echo "Config file not found: $env_file" >&2; exit 1; }
  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
}

# Detect default external interface if EXTERNAL_INTERFACE not set
detect_external_interface() {
  if [ -n "${EXTERNAL_INTERFACE:-}" ]; then
    echo "$EXTERNAL_INTERFACE"
    return 0
  fi
  local iface
  iface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1); exit}}}')
  if [ -z "$iface" ]; then
    iface=$(ip r | awk '/default/ {for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1); exit}}}')
  fi
  echo "$iface"
}

# Increment an IPv4 address by 1 (returns next IP)
ip_inc() {
  local IFS=.
  local a b c d
  read -r a b c d <<<"$1"
  d=$((d+1))
  if [ $d -gt 255 ]; then c=$((c+1)); d=0; fi
  if [ $c -gt 255 ]; then b=$((b+1)); c=0; fi
  if [ $b -gt 255 ]; then a=$((a+1)); b=0; fi
  echo "$a.$b.$c.$d"
}

# Check if IP is already assigned in peers directory
ip_in_use() {
  local ip="$1" peers_dir="$2"
  grep -R "^CLIENT_ADDRESS=${ip}$" "$peers_dir"/*/meta.env 2>/dev/null 1>/dev/null && return 0 || return 1
}

# Allocate next available peer IP from starting IP within WG_ADDRESS CIDR /24 (simple check)
alloc_next_ip() {
  local start_ip="$1" peers_dir="$2"
  local net_prefix
  net_prefix=$(echo "$start_ip" | awk -F. '{print $1"."$2"."$3"."}')
  local current="$start_ip"
  for _ in $(seq 2 254); do
    if ! ip_in_use "$current" "$peers_dir"; then
      echo "$current"
      return 0
    fi
    current=$(ip_inc "$current")
    case "$current" in
      ${net_prefix}0|${net_prefix}255) current=$(ip_inc "$current");;
    esac
  done
  echo "No available IPs in /24 starting at $start_ip" >&2
  return 1
}

# Render client config by substituting variables into template
render_client_conf() {
  local template="$1" output="$2"
  envsubst < "$template" > "$output"
}
