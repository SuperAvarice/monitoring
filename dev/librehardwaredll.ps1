# Specify the path to the LibreHardwareMonitorLib.dll
$BASE_DIR = "C:\Users\James\AppData\Local\Monitoring"
$dllPath = Join-Path -Path $BASE_DIR -ChildPath "\LibreHardwareMonitor\LibreHardwareMonitorLib.dll"

try {
    Unblock-File -LiteralPath $dllPath
    Add-Type -Path $dllPath

    $computer = New-Object -TypeName LibreHardwareMonitor.Hardware.Computer

    $computer.IsCpuEnabled         = $true
    $computer.IsGpuEnabled         = $true
    $computer.IsMemoryEnabled      = $true
    $computer.IsMotherboardEnabled = $true
    $computer.IsNetworkEnabled     = $true
    $computer.IsPsuEnabled         = $true
    $computer.IsStorageEnabled     = $true
    $computer.IsControllerEnabled  = $true
    $computer.IsBatteryEnabled     = $true

    $computer.Open()

    # Start-Sleep -Seconds 1

    foreach ($hardware in $computer.Hardware) {
        Write-Host "$($hardware.HardwareType) | $($hardware.Name)"
        $hardware.Update()

        foreach ($subhardware in $hardware.SubHardware) {
            Write-Host "`t$($subhardware.Name)"
            foreach ($sensor in $subhardware.Sensors) {
                Write-Host "`t`t$($sensor.Name) ---> $($sensor.Value)"
            }
        }

        foreach ($sensor in $hardware.Sensors) {
            Write-Host "`t$($sensor.Name) ---> $($sensor.Value)"
        }
    }
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
} finally {
    if ($computer) {
        $computer.Close()
    }
}
