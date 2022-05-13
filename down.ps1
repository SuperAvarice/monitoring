# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$SCRIPT_PATH = split-path -parent $PSCommandPath
Set-Location ${SCRIPT_PATH}

$SETUP_FILE = "${SCRIPT_PATH}\setup.ps1"
if (!(Test-Path $SETUP_FILE)) {
    Write-Host "Setup file not found."
    exit
}
. $SETUP_FILE

Write-Host ""
Write-Host "Stop Telegraf Service."
& "${BASE_DIR}\telegraf-${TELEGRAF_VER}\telegraf.exe" --service stop

Write-Host ""
Write-Host "Docker Compose Down."
docker-compose down
