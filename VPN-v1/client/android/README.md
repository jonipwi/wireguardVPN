# Android Client

1) Install the WireGuard app from the Play Store.
2) Ask the server admin to show a QR code for your profile:
   - On the server: `server/scripts/show-qr.sh server/peers/<name>/<name>.conf`
3) In the app, tap +, Scan from QR, and import the config.
4) Activate the tunnel.

Alternatively, you can transfer the `.conf` file and import it.
