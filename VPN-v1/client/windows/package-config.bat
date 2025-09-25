@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
  echo Usage: %~nx0 path\to\client.conf
  exit /b 1
)

set CONF=%~1
if not exist "%CONF%" (
  echo Not found: %CONF%
  exit /b 1
)

set NAME=%~n1
set OUT=%NAME%-wireguard.zip

powershell -NoProfile -Command "Compress-Archive -Path '%CONF%' -DestinationPath '%OUT%' -Force"
echo Created %OUT%

endlocal
