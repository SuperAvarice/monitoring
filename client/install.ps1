# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Some interesting Powershell reference code
# https://github.com/Lifailon/PowerShell.HardwareMonitor/blob/rsa/Module/HardwareMonitor/0.4/HardwareMonitor.psm1

# Install Monitoring
Write-Host "Begin Monitoring Setup."
Write-Host ""

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}

$SCRIPT_PATH = split-path -parent $PSCommandPath
Set-Location ${SCRIPT_PATH}

Write-Host ""

$SETUP_FILE = "${SCRIPT_PATH}\setup.ps1"
if (!(Test-Path $SETUP_FILE)) {
    Write-Host "Creating setup.ps1 with default values."
    Add-Content $SETUP_FILE "`$BASE_DIR `= `"$env:USERPROFILE\AppData\Local\Monitoring`""
    Add-Content $SETUP_FILE "`$INFLUX_OUTPUT_HOST `= `"localhost`""
    Add-Content $SETUP_FILE "`$LOGGING_INTERVAL `= `"20s`""
}
. $SETUP_FILE

$LHM_CONFIG = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <appSettings>
    <add key="startMinMenuItem" value="true" />
    <add key="minTrayMenuItem" value="true" />
    <add key="minCloseMenuItem" value="true" />
    <add key="runWebServerMenuItem" value="true" />
    <add key="nicMenuItem" value="false" />
    <add key="psuMenuItem" value="false" />
    <add key="batteryMenuItem" value="false" />
  </appSettings>
</configuration>
"@

Write-Host "Current Settings:"
Write-Host "Base Directory == $BASE_DIR"
Write-Host "Influx Output Host == $INFLUX_OUTPUT_HOST"
Write-Host "Logging Interval == $LOGGING_INTERVAL"
Write-Host ""
Write-Host "Continue install with these settings?"
$answ = read-host
$yes = @("yes", "Yes", "YES", "Y", "y")

if ($yes -contains $answ) {

    if (!(Test-Path ${BASE_DIR})) {
        $ProgressPreference = 'SilentlyContinue' # This exponentially speeds up Invoke-WebRequest
        # https://stackoverflow.com/questions/28682642/powershell-why-is-using-invoke-webrequest-much-slower-than-a-browser-download

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

        $TELEGRAF_API_URL = "https://api.github.com/repos/influxdata/telegraf/releases/latest"
        $TELEGRAF_VERSION = (Invoke-RestMethod -Uri $TELEGRAF_API_URL).tag_name -replace '^v',''
        $TELEGRAF_ZIP = "telegraf-${TELEGRAF_VERSION}_windows_amd64.zip"
        $TELEGRAF_DOWNLOAD_URL = "https://dl.influxdata.com/telegraf/releases/${TELEGRAF_ZIP}"
        Invoke-WebRequest -Uri $TELEGRAF_DOWNLOAD_URL -OutFile ${BASE_DIR}\${TELEGRAF_ZIP}
        Expand-Archive -Path ${BASE_DIR}\${TELEGRAF_ZIP} -DestinationPath ${BASE_DIR}
        Remove-Item ${BASE_DIR}\${TELEGRAF_ZIP}
        Copy-Item -Path "${BASE_DIR}\telegraf-${TELEGRAF_VERSION}\telegraf.exe" -Destination "${BASE_DIR}\telegraf"
        Remove-Item "${BASE_DIR}\telegraf-${TELEGRAF_VERSION}\" -Recurse

        Write-Host ""
        Write-Host "Download LibreHardwareMonitor."
        $LHM_PATH = "${BASE_DIR}\LibreHardwareMonitor"
        $LHM_ZIP = "${LHM_PATH}.zip"
        $LHM_API_URL = "https://api.github.com/repos/LibreHardwareMonitor/LibreHardwareMonitor/releases/latest"
        $LHM_RELEASES = Invoke-RestMethod -Uri $LHM_API_URL
        foreach ($asset in $LHM_RELEASES.assets) {
            if ($asset.name -like "LibreHardwareMonitor.zip") {
                $LHM_DOWNLOAD_URL = $asset.browser_download_url
            }
        }
        Invoke-WebRequest -Uri $LHM_DOWNLOAD_URL -OutFile $LHM_ZIP
        Expand-Archive -Path $LHM_ZIP -DestinationPath $LHM_PATH
        Remove-Item $LHM_ZIP

        Set-Location ${BASE_DIR}

        Write-Host ""
        Write-Host "Start and Configure LibreHardwareMonitor."
        try {
            $LHM_CONFIG | Out-File -FilePath "$LHM_PATH\LibreHardwareMonitor.config" -Encoding utf8 -Force
        } catch {
            Write-Error "Failed to write LibreHardwareMonitor.config: $_"
            exit 1
        }
        try {
            Start-Process -FilePath "$LHM_PATH\LibreHardwareMonitor.exe" -WorkingDirectory $LHM_PATH -WindowStyle Hidden
        } catch {
            Write-Error "Failed to start LibreHardwareMonitor: $_"
            exit 1
        }

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
Write-Host "End Monitoring Setup."
Pause
