# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

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

    Copy-Item ".\*.yml" -Destination ${BASE_DIR} -force
    Copy-Item ".\.env" -Destination ${BASE_DIR} -force
    Copy-Item -Path ".\grafana" -Destination ${BASE_DIR} -Recurse -force
    Copy-Item -Path ".\telegraf\*" -Destination ${BASE_DIR}\telegraf -force

    $OUT_DIR = $BASE_DIR.Replace("\","\\")
    $FILE_DATA = Get-Content ${BASE_DIR}\telegraf\telegraf.conf
    $FILE_DATA = $FILE_DATA.Replace("LIBRE*HARDWARE*FILE", "${OUT_DIR}\\telegraf\\librehardware.ps1")
    $FILE_DATA | Out-File -encoding ASCII ${BASE_DIR}\telegraf\telegraf.conf
}
