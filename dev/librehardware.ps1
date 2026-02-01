# Get Libre Hardware data
#
# Copied and modified from the original. 
# openhardware.ps1 (c) 2021 Matthew J. Ernisse <matt@going-flying.com>

$hardware = Get-WmiObject -Namespace root/LibreHardwareMonitor -Query 'SELECT HardwareType,Identifier,Name FROM Hardware'
$sensors = Get-WmiObject -Namespace root/LibreHardwareMonitor -Query 'SELECT Value,Name,Parent,SensorType FROM Sensor'
foreach ($sensor in $sensors) {
    $htype = "None"
    $id = "None"
    foreach ($item in $hardware) {
        if ($item.Identifier -eq $sensor.Parent) {
            $id = $item.Name -replace "\s+", "\ "
            $htype = $item.HardwareType
            break
        }
    }
    $name = $sensor.Name -replace "\s+", "\ "
    $hostname = $env:COMPUTERNAME
    $hostname = $hostname.substring(0,1).toupper()+$hostname.substring(1).tolower()
    Write-Host -NoNewline "lhm,host=$hostname,hardware_id=$($sensor.Parent),hardware_name=$id,hardware_type=$htype,type=$($sensor.SensorType),name=$name value=$($sensor.Value)`n"
}
