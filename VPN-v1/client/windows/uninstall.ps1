# Remove all WireGuard tunnel services
Param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "[+] Listing WireGuard tunnel services..."

# Find wireguard.exe
$wgExeCmd = Get-Command wireguard.exe -ErrorAction SilentlyContinue
if ($wgExeCmd) {
  $wgExe = $wgExeCmd.Path
} else {
  $wgDefault = "C:\\Program Files\\WireGuard\\wireguard.exe"
  if (Test-Path $wgDefault) { $wgExe = $wgDefault } else { Write-Error "wireguard.exe not found"; exit 1 }
}

# List existing tunnels
$tunnels = & "$wgExe" /dumpconfig | Select-String "^interface:" | ForEach-Object { ($_ -split ":")[1].Trim() }

if (-not $tunnels) {
  Write-Host "No WireGuard tunnels found."
  exit 0
}

Write-Host "Found tunnels:"
$tunnels | ForEach-Object { Write-Host "  $_" }

if (-not $Force) {
  $confirm = Read-Host "Remove all tunnels? (y/N)"
  if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled."
    exit 0
  }
}

foreach ($tunnel in $tunnels) {
  Write-Host "Removing: $tunnel"
  & "$wgExe" /uninstalltunnelservice "$tunnel"
}

Write-Host "[+] All WireGuard tunnels removed."