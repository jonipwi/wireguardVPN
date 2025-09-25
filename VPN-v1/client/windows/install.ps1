Param(
  [string]$Folder = "."
)

$ErrorActionPreference = "Stop"

Write-Host "[+] Importing WireGuard profiles from $Folder"

# Find wireguard.exe
$wgExeCmd = Get-Command wireguard.exe -ErrorAction SilentlyContinue
if ($wgExeCmd) {
  $wgExe = $wgExeCmd.Path
} else {
  $wgDefault = "C:\\Program Files\\WireGuard\\wireguard.exe"
  if (Test-Path $wgDefault) { $wgExe = $wgDefault } else { Write-Error "wireguard.exe not found. Install WireGuard for Windows first."; exit 1 }
}

$confFiles = Get-ChildItem -Path $Folder -Filter *.conf -File -Recurse
if (-not $confFiles) {
  Write-Warning "No .conf files found in $Folder"
  exit 0
}

foreach ($f in $confFiles) {
  Write-Host "  -> $($f.FullName)"
  & "$wgExe" /installtunnelservice "$($f.FullName)"
}

Write-Host "[+] Done. Profiles installed as Windows services. Open WireGuard UI to manage/activate them."
