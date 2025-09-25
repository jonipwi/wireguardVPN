# WireGuard VPN Project for Windows

## Project Overview

This project implements a complete WireGuard VPN solution for Windows, including server setup, client configuration, and management tools. WireGuard is a modern, fast, and secure VPN protocol that's easier to configure than traditional VPN solutions.

## Architecture

```
[Client Windows Machine] ←→ [WireGuard Server] ←→ [Internet/Private Network]
```

## Prerequisites

- Windows 10/11 (for client)
- Windows Server or Linux server (for VPN server)
- Administrator privileges
- Basic networking knowledge
- PowerShell 5.1 or later

## Part 1: Server Setup (Ubuntu/Debian)

### 1.1 Install WireGuard on Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install WireGuard
sudo apt install wireguard -y

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 1.2 Generate Server Keys

```bash
# Navigate to WireGuard directory
cd /etc/wireguard

# Generate private key
sudo wg genkey | sudo tee server_private.key

# Generate public key from private key
sudo cat server_private.key | wg pubkey | sudo tee server_public.key

# Set proper permissions
sudo chmod 600 server_private.key
```

### 1.3 Server Configuration

Create `/etc/wireguard/wg0.conf`:

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = [SERVER_PRIVATE_KEY]
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Windows Client Configuration
[Peer]
PublicKey = [CLIENT_PUBLIC_KEY]
AllowedIPs = 10.0.0.2/32
```

## Part 2: Windows Client Implementation

### 2.1 Install WireGuard for Windows

```powershell
# Download and install WireGuard for Windows
# Option 1: Direct download from wireguard.com
Invoke-WebRequest -Uri "https://download.wireguard.com/windows-client/wireguard-installer.exe" -OutFile "wireguard-installer.exe"
Start-Process -FilePath "wireguard-installer.exe" -Wait

# Option 2: Using winget (Windows Package Manager)
winget install WireGuard.WireGuard
```

### 2.2 Generate Windows Client Keys

```powershell
# PowerShell script to generate WireGuard keys
function New-WireGuardKeys {
    $wgPath = "${env:ProgramFiles}\WireGuard\wg.exe"
    
    if (-not (Test-Path $wgPath)) {
        Write-Error "WireGuard not found. Please install WireGuard first."
        return
    }
    
    # Generate private key
    $privateKey = & $wgPath genkey
    
    # Generate public key
    $publicKey = $privateKey | & $wgPath pubkey
    
    return @{
        PrivateKey = $privateKey
        PublicKey = $publicKey
    }
}

# Generate keys for client
$clientKeys = New-WireGuardKeys
Write-Host "Client Private Key: $($clientKeys.PrivateKey)"
Write-Host "Client Public Key: $($clientKeys.PublicKey)"
```

### 2.3 Windows Client Configuration Manager

```powershell
# WireGuard Configuration Manager for Windows
class WireGuardManager {
    [string]$ConfigPath
    [string]$WireGuardPath
    
    WireGuardManager() {
        $this.ConfigPath = "${env:ProgramFiles}\WireGuard\Data\Configurations"
        $this.WireGuardPath = "${env:ProgramFiles}\WireGuard"
        
        # Create config directory if it doesn't exist
        if (-not (Test-Path $this.ConfigPath)) {
            New-Item -ItemType Directory -Path $this.ConfigPath -Force
        }
    }
    
    [void] CreateClientConfig([string]$name, [string]$serverIP, [string]$serverPort, 
                             [string]$clientPrivateKey, [string]$serverPublicKey, 
                             [string]$clientIP, [string]$allowedIPs, [string]$dns) {
        
        $configContent = @"
[Interface]
PrivateKey = $clientPrivateKey
Address = $clientIP
DNS = $dns

[Peer]
PublicKey = $serverPublicKey
Endpoint = ${serverIP}:${serverPort}
AllowedIPs = $allowedIPs
PersistentKeepalive = 25
"@
        
        $configFile = Join-Path $this.ConfigPath "$name.conf"
        $configContent | Out-File -FilePath $configFile -Encoding UTF8
        
        Write-Host "Configuration created: $configFile"
    }
    
    [void] InstallTunnel([string]$configName) {
        $wgExe = Join-Path $this.WireGuardPath "wireguard.exe"
        $configFile = Join-Path $this.ConfigPath "$configName.conf"
        
        if (-not (Test-Path $configFile)) {
            throw "Configuration file not found: $configFile"
        }
        
        # Install the tunnel
        & $wgExe /installtunnelservice $configFile
        Write-Host "Tunnel '$configName' installed successfully"
    }
    
    [void] StartTunnel([string]$tunnelName) {
        Start-Service -Name "WireGuardTunnel`$$tunnelName"
        Write-Host "Tunnel '$tunnelName' started"
    }
    
    [void] StopTunnel([string]$tunnelName) {
        Stop-Service -Name "WireGuardTunnel`$$tunnelName"
        Write-Host "Tunnel '$tunnelName' stopped"
    }
    
    [void] UninstallTunnel([string]$tunnelName) {
        $wgExe = Join-Path $this.WireGuardPath "wireguard.exe"
        & $wgExe /uninstalltunnelservice $tunnelName
        Write-Host "Tunnel '$tunnelName' uninstalled"
    }
    
    [array] GetTunnelStatus() {
        $services = Get-Service -Name "WireGuardTunnel*" -ErrorAction SilentlyContinue
        return $services | Select-Object Name, Status
    }
}
```

### 2.4 Automated Setup Script

```powershell
# Automated WireGuard VPN Setup Script for Windows
param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerPort = "51820",
    
    [Parameter(Mandatory=$false)]
    [string]$TunnelName = "MyVPN",
    
    [Parameter(Mandatory=$false)]
    [string]$DNS = "1.1.1.1, 8.8.8.8"
)

function Install-WireGuard {
    Write-Host "Checking WireGuard installation..."
    
    $wgPath = "${env:ProgramFiles}\WireGuard\wg.exe"
    if (-not (Test-Path $wgPath)) {
        Write-Host "Installing WireGuard..."
        
        # Download WireGuard installer
        $installerUrl = "https://download.wireguard.com/windows-client/wireguard-installer.exe"
        $installerPath = "$env:TEMP\wireguard-installer.exe"
        
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        Write-Host "WireGuard installed successfully"
    } else {
        Write-Host "WireGuard is already installed"
    }
}

function New-VPNConnection {
    param(
        [string]$ServerIP,
        [string]$ServerPort,
        [string]$TunnelName,
        [string]$DNS
    )
    
    # Initialize WireGuard Manager
    $wgManager = [WireGuardManager]::new()
    
    # Generate client keys
    Write-Host "Generating client keys..."
    $clientKeys = New-WireGuardKeys
    
    Write-Host "Client Public Key (share this with server admin):"
    Write-Host $clientKeys.PublicKey -ForegroundColor Green
    
    # Get server public key from user
    $serverPublicKey = Read-Host "Enter server public key"
    
    # Get client IP
    $clientIP = Read-Host "Enter client IP (e.g., 10.0.0.2/24)"
    
    # Create configuration
    Write-Host "Creating VPN configuration..."
    $wgManager.CreateClientConfig(
        $TunnelName,
        $ServerIP,
        $ServerPort,
        $clientKeys.PrivateKey,
        $serverPublicKey,
        $clientIP,
        "0.0.0.0/0",  # Route all traffic through VPN
        $DNS
    )
    
    Write-Host "VPN configuration created successfully!"
    Write-Host "You can now start the VPN using: Start-VPN -TunnelName '$TunnelName'"
}

function Start-VPN {
    param([string]$TunnelName)
    
    $wgManager = [WireGuardManager]::new()
    try {
        $wgManager.StartTunnel($TunnelName)
    } catch {
        # If service doesn't exist, install it first
        $wgManager.InstallTunnel($TunnelName)
        $wgManager.StartTunnel($TunnelName)
    }
}

function Stop-VPN {
    param([string]$TunnelName)
    
    $wgManager = [WireGuardManager]::new()
    $wgManager.StopTunnel($TunnelName)
}

function Get-VPNStatus {
    $wgManager = [WireGuardManager]::new()
    return $wgManager.GetTunnelStatus()
}

# Main execution
if ($ServerIP) {
    Install-WireGuard
    New-VPNConnection -ServerIP $ServerIP -ServerPort $ServerPort -TunnelName $TunnelName -DNS $DNS
}
```

## Part 3: Advanced Features

### 3.1 Connection Health Monitor

```powershell
function Monitor-VPNConnection {
    param(
        [string]$TunnelName,
        [int]$CheckIntervalSeconds = 30
    )
    
    while ($true) {
        $service = Get-Service -Name "WireGuardTunnel`$$TunnelName" -ErrorAction SilentlyContinue
        
        if ($service) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "[$timestamp] VPN Status: $($service.Status)" -ForegroundColor $(
                if ($service.Status -eq 'Running') { 'Green' } else { 'Red' }
            )
            
            # Test internet connectivity through VPN
            try {
                $response = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
                if ($response) {
                    Write-Host "[$timestamp] Internet connectivity: OK" -ForegroundColor Green
                } else {
                    Write-Host "[$timestamp] Internet connectivity: FAILED" -ForegroundColor Red
                }
            } catch {
                Write-Host "[$timestamp] Connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "[$timestamp] VPN tunnel '$TunnelName' not found" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}
```

### 3.2 GUI Application (Optional)

For a complete solution, you could create a simple GUI using Windows Forms:

```powershell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-VPNManager {
    # Create main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "WireGuard VPN Manager"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"
    
    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(10, 20)
    $statusLabel.Size = New-Object System.Drawing.Size(350, 30)
    $statusLabel.Text = "VPN Status: Disconnected"
    $form.Controls.Add($statusLabel)
    
    # Connect button
    $connectButton = New-Object System.Windows.Forms.Button
    $connectButton.Location = New-Object System.Drawing.Point(50, 80)
    $connectButton.Size = New-Object System.Drawing.Size(100, 30)
    $connectButton.Text = "Connect"
    $connectButton.Add_Click({
        try {
            Start-VPN -TunnelName "MyVPN"
            $statusLabel.Text = "VPN Status: Connected"
            $statusLabel.ForeColor = [System.Drawing.Color]::Green
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
        }
    })
    $form.Controls.Add($connectButton)
    
    # Disconnect button
    $disconnectButton = New-Object System.Windows.Forms.Button
    $disconnectButton.Location = New-Object System.Drawing.Point(200, 80)
    $disconnectButton.Size = New-Object System.Drawing.Size(100, 30)
    $disconnectButton.Text = "Disconnect"
    $disconnectButton.Add_Click({
        try {
            Stop-VPN -TunnelName "MyVPN"
            $statusLabel.Text = "VPN Status: Disconnected"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
        }
    })
    $form.Controls.Add($disconnectButton)
    
    # Show form
    $form.ShowDialog()
}
```

## Usage Instructions

### Quick Start

1. **Set up the server** using Part 1 instructions
2. **Run the setup script** on Windows:
   ```powershell
   .\WireGuardSetup.ps1 -ServerIP "YOUR_SERVER_IP"
   ```
3. **Share the client public key** with your server administrator
4. **Start the VPN connection**:
   ```powershell
   Start-VPN -TunnelName "MyVPN"
   ```

### Management Commands

```powershell
# Check VPN status
Get-VPNStatus

# Start VPN connection
Start-VPN -TunnelName "MyVPN"

# Stop VPN connection  
Stop-VPN -TunnelName "MyVPN"

# Monitor connection
Monitor-VPNConnection -TunnelName "MyVPN"

# Launch GUI manager
Show-VPNManager
```

## Security Considerations

1. **Key Management**: Store private keys securely, never share them
2. **Firewall Rules**: Configure Windows Firewall appropriately
3. **DNS Leaks**: Use VPN DNS servers to prevent DNS leaks
4. **Kill Switch**: Implement connection monitoring for automatic reconnection
5. **Updates**: Keep WireGuard and Windows updated regularly

## Troubleshooting

### Common Issues

1. **Connection fails**: Check server IP, port, and firewall settings
2. **DNS not working**: Verify DNS configuration in client config
3. **No internet**: Check AllowedIPs setting and server routing
4. **Service won't start**: Run PowerShell as Administrator

### Diagnostic Commands

```powershell
# Check WireGuard service
Get-Service -Name "WireGuardTunnel*"

# View network interfaces
Get-NetAdapter

# Test connectivity
Test-NetConnection -ComputerName "SERVER_IP" -Port 51820

# Check routing table
route print
```

## File Structure

```
WireGuardVPN-Project/
├── scripts/
│   ├── setup.ps1
│   ├── manager.ps1
│   └── monitor.ps1
├── configs/
│   └── client-templates/
├── docs/
│   └── README.md
└── gui/
    └── vpn-manager.ps1
```

This complete WireGuard VPN project provides a robust, secure, and manageable VPN solution for Windows environments. The modular design allows for easy customization and extension based on specific requirements.