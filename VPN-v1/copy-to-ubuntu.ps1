Compress-Archive -Path C:\Job\wireguardVPN\VPN-v1\* -DestinationPath c:\Job\wireguardVPN\VPN-v1\wireguardVPN.zip -Force
scp c:\Job\wireguardVPN\VPN-v1\wireguardVPN.zip user@your.server.com:/tmp/