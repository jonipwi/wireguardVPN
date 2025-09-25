# Linux Client

1) Install wireguard tools: `sudo apt install wireguard` or your distro equivalent.
2) Place your `client.conf` under `/etc/wireguard/` as `wg-client.conf` or any name.
3) Bring up: `sudo wg-quick up wg-client` (use your file basename).
4) Bring down: `sudo wg-quick down wg-client`.

Helper scripts:

- `up.sh <config>` — brings up a config
- `down.sh <config>` — brings down a config
