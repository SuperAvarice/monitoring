# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Install Monitoring
Write-Host "Begin Setup."
Write-Host ""

$IS_DOCKER_RUNNING = Get-Process 'com.docker.proxy'
if (!${IS_DOCKER_RUNNING}) {
    Write-Host "Docker for Windows must be installed and running."
    Write-Host "https://docs.docker.com/desktop/windows/install/"
    exit
}

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

$SCRIPT_PATH = split-path -parent $PSCommandPath
Set-Location ${SCRIPT_PATH}

$SETUP_FILE = "${SCRIPT_PATH}\setup.ps1"
if (!(Test-Path $SETUP_FILE)) {
    Add-Content $SETUP_FILE "`$BASE_DIR `= `"$env:USERPROFILE\AppData\Local\Monitoring`""
    Add-Content $SETUP_FILE "`$TELEGRAF_VER `= `"1.21.4`""
    Add-Content $SETUP_FILE "`$LIBRE_HARDWARE_VER `= `"0.8.9`""
    Add-Content $SETUP_FILE "Write-Host `"Base Directory == `$BASE_DIR`""
    Add-Content $SETUP_FILE "Write-Host `"Telegraf Version == `$TELEGRAF_VER`""
    Add-Content $SETUP_FILE "Write-Host `"Libre Hardware Version == `$LIBRE_HARDWARE_VER`""
}
. $SETUP_FILE

if (!(Test-Path ${BASE_DIR})) {
    New-Item -ItemType Directory -Force -Path  ${BASE_DIR} | Out-Null
    Copy-Item ".\*.yml" -Destination ${BASE_DIR}
    Copy-Item ".\.env" -Destination ${BASE_DIR}
    Copy-Item -Path ".\grafana" -Destination ${BASE_DIR} -Recurse
    Copy-Item -Path ".\telegraf" -Destination ${BASE_DIR} -Recurse
    New-Item -ItemType Directory -Force -Path  ${BASE_DIR}\grafana\data | Out-Null
    New-Item -ItemType Directory -Force -Path  ${BASE_DIR}\influx\data | Out-Null
    New-Item -ItemType Directory -Force -Path  ${BASE_DIR}\chronograf\data | Out-Null
 
    $OUT_DIR = $BASE_DIR.Replace("\","\\")
    $FILE_DATA = Get-Content ${BASE_DIR}\telegraf\telegraf.conf
    $FILE_DATA = $FILE_DATA.Replace("LIBRE*HARDWARE*FILE", "${OUT_DIR}\\telegraf\\librehardware.ps1")
    $FILE_DATA | Out-File -encoding ASCII ${BASE_DIR}\telegraf\telegraf.conf

    Write-Host ""
    Write-Host "Download Telegraf."
    $TELEGRAF_ZIP = "telegraf-${TELEGRAF_VER}_windows_amd64.zip"
    $TELEGRAF_DOWNLOAD = "https://dl.influxdata.com/telegraf/releases/${TELEGRAF_ZIP}"
    Invoke-WebRequest ${TELEGRAF_DOWNLOAD} -UseBasicParsing -OutFile "${TELEGRAF_ZIP}"
    Expand-Archive .\${TELEGRAF_ZIP} -DestinationPath "${BASE_DIR}"
    Remove-Item ${TELEGRAF_ZIP}

    Write-Host ""
    Write-Host "Download LibreHardwareMonitor."
    $LIBRE_HARDWARE_ZIP = "LibreHardwareMonitor-net452.zip"
    $LIBRE_DOWNLOAD = "https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/download/v${LIBRE_HARDWARE_VER}/${LIBRE_HARDWARE_ZIP}"
    Invoke-WebRequest ${LIBRE_DOWNLOAD} -UseBasicParsing -OutFile "${LIBRE_HARDWARE_ZIP}"
    Expand-Archive ".\${LIBRE_HARDWARE_ZIP}" -DestinationPath "${BASE_DIR}\LibreHardwareMonitor"
    Remove-Item ${LIBRE_HARDWARE_ZIP}

    Set-Location ${BASE_DIR}

    Write-Host ""
    Write-Host "Start and Configure LibreHardwareMonitor."
    Write-Host "Options (Enable) -> Start Minimized, Minimize To Tray, Minimize On Close, Run On Windows Startup"
    Write-Host "File -> Hardware (Disable) -> Network, Power supplies"
    Start-Process "${BASE_DIR}\LibreHardwareMonitor\LibreHardwareMonitor.exe"
    Pause

    Write-Host ""
    Write-Host "Install and Start Telegraf Service."
    & "${BASE_DIR}\telegraf-${TELEGRAF_VER}\telegraf.exe" --service install --config "${BASE_DIR}\telegraf\telegraf.conf"
    & "${BASE_DIR}\telegraf-${TELEGRAF_VER}\telegraf.exe" --service start

    Write-Host ""
    Write-Host "Downloading the Unifi MIBS."
    Invoke-WebRequest "https://dl.ubnt-ut.com/snmp/UBNT-MIB" -UseBasicParsing -OutFile "${BASE_DIR}\telegraf\UBNT-MIB"
    Invoke-WebRequest "https://dl.ubnt-ut.com/snmp/UBNT-UniFi-MIB" -UseBasicParsing -OutFile "${BASE_DIR}\telegraf\UBNT-UniFi-MIB"

    Write-Host ""
    Write-Host "In the Unifi Controller System Setup"
    Write-Host " --> Enable SNMP Version 1 & 2."
    Write-Host " --> Add a View Only user with STATS permission. Update the .env file in the install location with that info. Is best to use the Legacy Interface."
    Pause

    Write-Host ""
    Write-Host "Docker Compose Up."
    docker-compose up -d
} else {
    Write-Host "${BASE_DIR} already exists, delete it to re-install."
}

Write-Host "End Setup."
Pause
