# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Install Monitoring
Write-Host "Begin Setup."
Write-Host ""

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

$SCRIPT_PATH = split-path -parent $PSCommandPath
Set-Location ${SCRIPT_PATH}

Write-Host "For the latest version of Telegraf: https://www.influxdata.com/downloads/"
Write-Host "For the latest version of LibreHardwareMonitor: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases"
Write-Host ""

$SETUP_FILE = "${SCRIPT_PATH}\setup.ps1"
if (!(Test-Path $SETUP_FILE)) {
    Add-Content $SETUP_FILE "`$BASE_DIR `= `"$env:USERPROFILE\AppData\Local\Monitoring`""
    Add-Content $SETUP_FILE "`$INFLUX_OUTPUT_HOST `= `"localhost`""
    Add-Content $SETUP_FILE "`$LOGGING_INTERVAL `= `"10s`""
    Add-Content $SETUP_FILE "`$TELEGRAF_VER `= `"1.34.0`""
    Add-Content $SETUP_FILE "`$LIBRE_HARDWARE_VER `= `"0.9.4`""
}
. $SETUP_FILE

Write-Host "Base Directory == $BASE_DIR"
Write-Host "Influx Output Host == $INFLUX_OUTPUT_HOST"
Write-Host "Logging Interval == $LOGGING_INTERVAL"
Write-Host "Telegraf Version == $TELEGRAF_VER"
Write-Host "Libre Hardware Version == $LIBRE_HARDWARE_VER"
Write-Host ""
Write-Host "Continue install with these settings?"
$answ = read-host
$yes = @("yes", "Yes", "YES", "Y", "y")

if ($yes -contains $answ) {

    if (!(Test-Path ${BASE_DIR})) {
        New-Item -ItemType Directory -Force -Path  ${BASE_DIR} | Out-Null
        Copy-Item -Path ".\telegraf" -Destination ${BASE_DIR} -Recurse

        $OUT_DIR = $BASE_DIR.Replace("\", "\\")
        $FILE_DATA = Get-Content ${BASE_DIR}\telegraf\telegraf.conf
        $FILE_DATA = $FILE_DATA.Replace("LIBRE*HARDWARE*FILE", "${OUT_DIR}\\telegraf\\librehardware.ps1")
        $FILE_DATA = $FILE_DATA.Replace("LOGGING*INTERVAL", "${LOGGING_INTERVAL}")
        $FILE_DATA = $FILE_DATA.Replace("INFLUX*OUTPUT*HOST", "${INFLUX_OUTPUT_HOST}")
        $FILE_DATA | Out-File -encoding ASCII ${BASE_DIR}\telegraf\telegraf.conf

        Write-Host ""
        Write-Host "Download Telegraf."
        $TELEGRAF_ZIP = "telegraf-${TELEGRAF_VER}_windows_amd64.zip"
        $TELEGRAF_DOWNLOAD = "https://dl.influxdata.com/telegraf/releases/${TELEGRAF_ZIP}"
        Invoke-WebRequest ${TELEGRAF_DOWNLOAD} -UseBasicParsing -OutFile "${TELEGRAF_ZIP}"
        Expand-Archive .\${TELEGRAF_ZIP} -DestinationPath "${BASE_DIR}"
        Remove-Item ${TELEGRAF_ZIP}
        Copy-Item -Path "${BASE_DIR}\telegraf-${TELEGRAF_VER}\telegraf.exe" -Destination "${BASE_DIR}\telegraf"
        Remove-Item "${BASE_DIR}\telegraf-${TELEGRAF_VER}\" -Recurse

        Write-Host ""
        Write-Host "Download LibreHardwareMonitor."
        $LIBRE_HARDWARE_ZIP = "LibreHardwareMonitor-net472.zip"
        $LIBRE_DOWNLOAD = "https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/download/v${LIBRE_HARDWARE_VER}/${LIBRE_HARDWARE_ZIP}"
        Invoke-WebRequest ${LIBRE_DOWNLOAD} -UseBasicParsing -OutFile "${LIBRE_HARDWARE_ZIP}"
        Expand-Archive ".\${LIBRE_HARDWARE_ZIP}" -DestinationPath "${BASE_DIR}\LibreHardwareMonitor"
        Remove-Item ${LIBRE_HARDWARE_ZIP}

        Set-Location ${BASE_DIR}

        Write-Host ""
        Write-Host "Start and Configure LibreHardwareMonitor."
        Write-Host "Options (Enable) -> Start Minimized, Minimize To Tray, Minimize On Close, Run On Windows Startup"
        Write-Host "File -> Hardware (Disable) -> Network, Power supplies, Batteries"
        Start-Process "${BASE_DIR}\LibreHardwareMonitor\LibreHardwareMonitor.exe"
        Pause

        Write-Host ""
        Write-Host "Install and Start Telegraf Service."
        & "${BASE_DIR}\telegraf\telegraf.exe" --config "${BASE_DIR}\telegraf\telegraf.conf" service install
        & "${BASE_DIR}\telegraf\telegraf.exe" service start

        Set-Location ${SCRIPT_PATH}
    }
    else {
        Write-Host "${BASE_DIR} already exists, run uninstall.ps1 first."
    }
}
Write-Host "End Setup."
Pause
