# Quick Deployment Guide

## 1. Server Setup (Ubuntu/Debian)

### Copy project to server
```bash
# On your local machine (PowerShell)
Compress-Archive -Path c:\Job\wireguardVPN\* -DestinationPath c:\Job\wireguardVPN.zip -Force
scp c:\Job\wireguardVPN.zip user@your.server.com:/tmp/

# On the server
cd ~
unzip /tmp/wireguardVPN.zip -d wireguardVPN/
cd wireguardVPN/server
```

### Configure
```bash
# Copy example config and edit
cp config.env.example config.env
nano config.env
# At minimum, set SERVER_HOST to your domain or public IP
```

### Install and start
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the complete setup
./scripts/setup-and-test.sh
```

This will:
- Install WireGuard and dependencies
- Generate server keys
- Create wg0.conf and start the service  
- Create a test peer with QR code
- Show status

### Configure firewall
```bash
./scripts/configure-firewall.sh
```

## 2. Add Clients

### Add a peer
```bash
cd ~/wireguardVPN/server/scripts
./add-peer.sh alice
./show-qr.sh ../peers/alice/alice.conf  # For mobile
```

### Download client config
```bash
# From your PC
scp user@your.server.com:~/wireguardVPN/server/peers/alice/alice.conf ./alice.conf
```

## 3. Client Setup

### Windows
```powershell
cd c:\Job\wireguardVPN\client\windows
.\install.ps1 -Folder C:\path\to\configs
```

### Linux  
```bash
cd client/linux
chmod +x *.sh
./up.sh /path/to/alice.conf
```

### Android
Use the QR code from `show-qr.sh` output.

## 4. Management

```bash
./scripts/list-peers.sh           # Show connected peers
./scripts/remove-peer.sh alice    # Remove a peer
./scripts/rebuild-wg.sh          # Rebuild server config
```

## 5. Troubleshooting

```bash
sudo systemctl status wg-quick@wg0
sudo wg show
journalctl -u wg-quick@wg0 -f
```