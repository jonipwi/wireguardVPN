# WireGuard VPN Project

A complete, production-ready WireGuard VPN solution with automated server setup, peer management, and cross-platform client support.

## 📁 Project Structure

```
wireguardVPN/
├── git-run.ps1                 # Git automation script
├── VPN-v1/                     # Main VPN implementation
│   ├── copy-to-ubuntu.ps1      # Deploy to Ubuntu server
│   ├── on-server-ubuntu.ps1    # Server-side setup script
│   ├── validate-project.ps1    # Project validation
│   ├── DEPLOYMENT.md           # Detailed deployment guide
│   ├── server/                 # Server configuration & scripts
│   │   ├── config.env          # Main configuration file
│   │   ├── config.env.example  # Example configuration
│   │   ├── scripts/            # Management scripts
│   │   │   ├── install.sh      # Install WireGuard & dependencies
│   │   │   ├── generate-server.sh # Generate server keys & config
│   │   │   ├── add-peer.sh     # Add new VPN client
│   │   │   ├── remove-peer.sh  # Remove VPN client
│   │   │   ├── list-peers.sh   # List connected peers
│   │   │   ├── show-qr.sh      # Show QR code for mobile
│   │   │   ├── setup-and-test.sh # Complete setup with test
│   │   │   ├── test-installation.sh # Validate installation
│   │   │   ├── configure-firewall.sh # Configure firewall
│   │   │   ├── rebuild-wg.sh   # Rebuild WireGuard config
│   │   │   └── utils.sh        # Utility functions
│   │   ├── templates/          # Configuration templates
│   │   │   ├── server.conf.tpl # Server config template
│   │   │   └── client.conf.tpl # Client config template
│   │   └── peers/              # Generated client configs (git-ignored)
│   └── client/                 # Client setup tools
│       ├── windows/            # Windows client tools
│       │   ├── install.ps1     # Install configs to WireGuard app
│       │   ├── uninstall.ps1   # Remove all tunnels
│       │   ├── package-config.bat # Package config for distribution
│       │   └── README.md       # Windows setup instructions
│       ├── linux/              # Linux client tools
│       │   ├── up.sh           # Bring up VPN connection
│       │   ├── down.sh         # Bring down VPN connection
│       │   └── README.md       # Linux setup instructions
│       └── android/            # Android client instructions
│           └── README.md       # Android QR code setup
└── VPN-v2/                     # Future version (placeholder)
    └── README.md
```

## 🚀 Quick Start

### 1. Windows Setup (Development Machine)

```powershell
# Validate project structure
cd c:\Job\wireguardVPN\VPN-v1
.\validate-project.ps1

# Configure server settings
cp server\config.env.example server\config.env
# Edit server\config.env - set SERVER_HOST to your domain/IP

# Deploy to Ubuntu server
.\copy-to-ubuntu.ps1 user@your-server.com
```

### 2. Ubuntu Server Setup

```bash
# On your Ubuntu/Debian server
cd ~/wireguardVPN/VPN-v1

# Run the automated setup
.\on-server-ubuntu.ps1

# Or manual setup:
chmod +x server/scripts/*.sh client/linux/*.sh
./server/scripts/setup-and-test.sh
```

### 3. Add VPN Clients

```bash
# Add a new peer
./server/scripts/add-peer.sh alice

# Show QR code for mobile devices
./server/scripts/show-qr.sh server/peers/alice/alice.conf

# List connected peers
./server/scripts/list-peers.sh
```

## 🔧 Configuration

### Server Configuration (`server/config.env`)

```bash
# Public endpoint (REQUIRED - set to your domain or public IP)
SERVER_HOST=vpn.example.com

# Network settings
WG_PORT=51820                    # WireGuard UDP port
WG_ADDRESS=10.8.0.1/24          # Server interface IP/CIDR
PEER_START_IP=10.8.0.2          # First client IP

# Client settings
DNS=1.1.1.1, 1.0.0.1            # DNS servers for clients
CLIENT_ALLOWED_IPS=0.0.0.0/0, ::/0  # Route all traffic (or specific subnets)
PERSISTENT_KEEPALIVE=25          # NAT keepalive (seconds)

# Optional
WG_MTU=                          # Custom MTU (empty = auto)
EXTERNAL_INTERFACE=              # Network interface (auto-detected)
EXTRA_POST_UP=                   # Additional iptables rules
EXTRA_POST_DOWN=                 # Additional cleanup rules
```

## 📱 Client Setup

### Windows
```powershell
cd client\windows
.\install.ps1 -Folder "C:\path\to\configs"
```

### Linux
```bash
cd client/linux
./up.sh /path/to/client.conf
./down.sh client  # Bring down connection
```

### Android/iOS
1. Get QR code: `./server/scripts/show-qr.sh server/peers/name/name.conf`
2. Install WireGuard app from app store
3. Scan QR code to import configuration
4. Activate the tunnel

## 🛠️ Management Commands

| Command | Description |
|---------|-------------|
| `./server/scripts/list-peers.sh` | Show connected clients |
| `./server/scripts/add-peer.sh <name>` | Add new VPN client |
| `./server/scripts/remove-peer.sh <name>` | Remove VPN client |
| `./server/scripts/show-qr.sh <config>` | Generate QR code |
| `./server/scripts/test-installation.sh` | Validate server setup |
| `./server/scripts/configure-firewall.sh` | Configure firewall rules |
| `./server/scripts/rebuild-wg.sh` | Rebuild server configuration |

## 🔒 Security Features

- **Key Management**: Private keys stored securely, never committed to git
- **Automatic IP Allocation**: Prevents IP conflicts
- **Firewall Integration**: Automatic iptables/UFW configuration  
- **Permission Hardening**: Restricted file permissions on keys and configs
- **Network Isolation**: Configurable routing and DNS

## 🐛 Troubleshooting

### Server Issues
```bash
# Check WireGuard service
sudo systemctl status wg-quick@wg0

# View service logs
journalctl -u wg-quick@wg0 -f

# Check interface status
sudo wg show

# Test connectivity
ping 10.8.0.1  # Server IP
```

### Client Issues
```bash
# Linux: Check connection
wg show
ip route | grep wg

# Windows: Use WireGuard GUI or PowerShell
# netsh interface show interface
```

### Common Solutions
- **Connection fails**: Check firewall rules, ensure UDP port open
- **No internet through VPN**: Verify IP forwarding enabled on server
- **DNS not working**: Check DNS settings in client config
- **Mobile QR scan fails**: Regenerate QR code with correct config

## 📋 System Requirements

### Server (Ubuntu/Debian)
- Ubuntu 20.04+ or Debian 11+
- Root or sudo access
- Public IP address or domain name
- UDP port access (default: 51820)

### Clients
- **Windows**: WireGuard for Windows app
- **Linux**: `wireguard-tools` package
- **Android/iOS**: WireGuard app from app store

## 🚀 Advanced Usage

### Custom Network Routing
```bash
# Split tunneling - route only specific subnets
CLIENT_ALLOWED_IPS=10.8.0.0/24,192.168.1.0/24
```

### Multiple Server Configs
```bash
# Run multiple WireGuard instances
cp server/config.env server/config-site2.env
# Edit port, network, etc.
# Deploy with custom config file
```

### Automated Backups
```bash
# Backup server keys and peer configs
tar -czf wireguard-backup-$(date +%Y%m%d).tar.gz server/keys server/peers
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Test changes with `validate-project.ps1`
4. Submit a pull request

## 📄 License

MIT License - Use at your own risk. See LICENSE file for details.

## 🆘 Support

- Check `DEPLOYMENT.md` for detailed setup instructions
- Review script comments for implementation details
- Validate setup with included test scripts
- Ensure firewall and network configuration is correct

---

**⚠️ Security Notice**: This creates a production VPN server. Ensure you understand the security implications and keep your server updated.