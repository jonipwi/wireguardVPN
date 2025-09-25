# WireGuard VPN Project

This repo provides a complete, reproducible WireGuard VPN setup with:
- Server (Ubuntu/Debian) provisioning and management
- Client profiles for Windows, Linux, and Android
- Automated key generation and peer configuration
- Simple peer add/remove lifecycle, with QR codes for mobile

Folders:
- `server/` — scripts and templates to install and manage the WireGuard server
- `client/windows/`, `client/linux/`, `client/android/` — client templates and small helpers

Caution: Always treat private keys and generated configs as secrets.

## Quick start

1) Edit `server/config.env` to match your domain/IP and network. At minimum set:
   - `SERVER_HOST` to your domain or public IP
   - `WG_ADDRESS` for the server interface (e.g., 10.8.0.1/24)
   - `WG_PORT` (default 51820)
2) On your Ubuntu/Debian server, copy this folder and run:
   - `server/scripts/install.sh`
   - `server/scripts/generate-server.sh`
3) Add a peer and get a QR for Android:
   - `server/scripts/add-peer.sh alice`
   - `server/scripts/show-qr.sh server/peers/alice/alice.conf`

## Requirements
- Ubuntu 20.04+ / Debian 11+ for server.
- `bash`, `wg`, `qrencode`, `gettext-base` (installed by scripts).
- Windows client: WireGuard app.
- Linux client: `wireguard-tools`.
- Android client: WireGuard app (scan QR of the config).

## Server scripts

- `install.sh` — installs packages, enables IP forwarding, creates dirs
- `generate-server.sh` — creates server keys and `wg0.conf` from template
- `add-peer.sh <name>` — creates a peer, client config, updates server config, and reloads
- `remove-peer.sh <name>` — removes peer from server and deletes files
- `list-peers.sh` — shows `wg` status and the allocated IPs
- `show-qr.sh <path-to-conf>` — prints a QR code for Android/iOS
- `rebuild-wg.sh` — re-applies `wg0.conf` via `wg-quick`
- `setup-and-test.sh` — complete setup with test peer creation
- `test-installation.sh` — validates the installation
- `configure-firewall.sh` — opens firewall ports

## Security notes
- Generated private keys are stored under `server/keys/` and `server/peers/<name>/`. Restrict permissions.
- Avoid committing generated keys/configs. This repo ships with a `.gitignore` accordingly.
- Rotate keys periodically if required.

## Troubleshooting
- Check `sudo systemctl status wg-quick@wg0` on the server.
- Confirm UDP port is open on cloud firewall and OS firewall.
- Verify routing and DNS entries in `server/config.env`.

## License
MIT. Use at your own risk.