# WireGuard VPN Project Validation Script for Windows
Write-Host "=== WireGuard VPN Project Validation ===" -ForegroundColor Green

$projectRoot = Get-Location
Write-Host "Project root: $projectRoot" -ForegroundColor Cyan

# Check required files
$requiredFiles = @(
    "README.md",
    "DEPLOYMENT.md", 
    ".gitignore",
    "server\config.env",
    "server\config.env.example",
    "server\templates\server.conf.tpl",
    "server\templates\client.conf.tpl",
    "server\scripts\install.sh",
    "server\scripts\generate-server.sh",
    "server\scripts\add-peer.sh",
    "server\scripts\remove-peer.sh",
    "server\scripts\list-peers.sh",
    "server\scripts\show-qr.sh",
    "server\scripts\utils.sh",
    "server\scripts\rebuild-wg.sh",
    "server\scripts\setup-and-test.sh",
    "server\scripts\test-installation.sh",
    "server\scripts\configure-firewall.sh",
    "client\windows\README.md",
    "client\windows\install.ps1",
    "client\windows\uninstall.ps1",
    "client\windows\package-config.bat",
    "client\linux\README.md",
    "client\linux\up.sh",
    "client\linux\down.sh",
    "client\android\README.md",
    "server\peers\.gitkeep"
)

Write-Host "Checking required files..." -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "Missing files found!" -ForegroundColor Red
    exit 1
}

# Check server config
Write-Host "Checking server configuration..." -ForegroundColor Yellow
if (Test-Path "server\config.env") {
    $config = Get-Content "server\config.env" | Where-Object { $_ -match "^SERVER_HOST=" }
    if ($config -and $config -notmatch "your\.domain\.example") {
        Write-Host "  SERVER_HOST configured" -ForegroundColor Green
    } else {
        Write-Host "  SERVER_HOST needs configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "  config.env not found" -ForegroundColor Red
}

Write-Host "=== Validation Complete ===" -ForegroundColor Green
Write-Host "Total files: $($(Get-ChildItem -Recurse -File).Count)" -ForegroundColor Cyan

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Configure server\config.env with your domain/IP"
Write-Host "  2. Copy project to your Ubuntu/Debian server"
Write-Host "  3. Run: chmod +x server/scripts/*.sh client/linux/*.sh"
Write-Host "  4. Run: server/scripts/setup-and-test.sh"
Write-Host "  5. See DEPLOYMENT.md for detailed instructions"