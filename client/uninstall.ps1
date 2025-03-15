# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# UnInstall Monitoring

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

$SCRIPT_PATH = split-path -parent $PSCommandPath
Set-Location ${SCRIPT_PATH}

$SETUP_FILE = "${SCRIPT_PATH}\setup.ps1"
if (!(Test-Path $SETUP_FILE)) {
    Write-Host "Setup file not found."
    exit
}
. $SETUP_FILE

if (Test-Path ${BASE_DIR}) {

    Write-Host "Exit the LibreHardwareMonitor application now."
    Pause

    Set-Location ${BASE_DIR}
    & "${BASE_DIR}\telegraf\telegraf.exe" service stop
    & "${BASE_DIR}\telegraf\telegraf.exe" service uninstall

    Set-Location ${SCRIPT_PATH}
    Remove-Item -Recurse -Force ${BASE_DIR}
}
Pause
