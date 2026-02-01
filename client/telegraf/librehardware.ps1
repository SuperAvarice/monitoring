# Purpose:
#   Fetch Prometheus text-format metrics emitted by LibreHardwareMonitor and
#   normalize the exposition so Telegraf's Prometheus parser can ingest it.
#
# What it does:
#   - Reads metrics from the LibreHardwareMonitor HTTP endpoint (default http://localhost:8085/metrics).
#   - Collapses/moves any "# TYPE" comment lines so that each metric has at most one
#     TYPE line immediately before that metric's samples.
#   - Removes all "# HELP" lines entirely (they have caused duplicate-HELP parsing errors).
#   - Preserves other comment lines and non-metric lines.
#   - Writes the cleaned Prometheus text output to stdout.
#
# Why:
#   LibreHardwareMonitor can emit duplicate or out-of-order "# HELP" and
#   "# TYPE" lines which violate the Prometheus text exposition format and
#   cause Telegraf's prometheus parser to fail with errors like: "second HELP line for metric name ..."
#   This script removes HELP lines and normalizes TYPE lines to avoid those errors.
#
# Usage:
#   - Place this script on the Telegraf host and call it from a [[inputs.exec]] entry in telegraf.conf.
#   - The script writes cleaned metrics to stdout for Telegraf to parse.

# Get Libre Hardware data
$Uri = 'http://localhost:8085/metrics'

try {
    $content = (Invoke-WebRequest -UseBasicParsing $Uri -ErrorAction Stop).Content
    $rawLines = $content -split "`r?`n"
} catch {
    Write-Error "Failed to read metrics: $_"
    exit 1
}

$order = New-Object System.Collections.ArrayList
# store only type and samples (HELP lines are intentionally discarded)
$metrics = @{}
$global = New-Object System.Collections.ArrayList

foreach ($line in $rawLines) {
    if ($null -eq $line -or $line -match '^\s*$') { continue }

    # Discard HELP lines entirely
    if ($line -match '^\s*#\s*HELP\s+(\S+)\s+(.*)$') {
        continue
    }

    # Capture TYPE lines (one per metric)
    if ($line -match '^\s*#\s*TYPE\s+(\S+)\s+(\S+)\s*$') {
        $name = $matches[1]
        if (-not $metrics.ContainsKey($name)) {
            $metrics[$name] = @{ type = $line; samples = New-Object System.Collections.ArrayList }
            [void]$order.Add($name)
        } elseif (-not $metrics[$name].type) {
            $metrics[$name].type = $line
        }
        continue
    }

    # Preserve other comment lines
    if ($line -match '^\s*#') {
        [void]$global.Add($line)
        continue
    }

    # Metric sample lines: group by metric name
    if ($line -match '^\s*([A-Za-z_:][A-Za-z0-9_:]*)\b(.*)$') {
        $name = $matches[1]
        if (-not $metrics.ContainsKey($name)) {
            $metrics[$name] = @{ type = $null; samples = New-Object System.Collections.ArrayList }
            [void]$order.Add($name)
        }
        [void]$metrics[$name].samples.Add($line)
        continue
    }

    # Any other lines are kept
    [void]$global.Add($line)
}

# Emit cleaned output: global comments first, then per-metric TYPE before samples (HELP omitted)
foreach ($g in $global) { Write-Output $g }

foreach ($name in $order) {
    $m = $metrics[$name]
    if ($m.type) { Write-Output $m.type }
    foreach ($s in $m.samples) { Write-Output $s }
}
exit 0
