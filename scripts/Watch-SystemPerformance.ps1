<#
.SYNOPSIS
    Collects Windows system performance and network latency metrics.

.DESCRIPTION
    Watch-SystemPerformance samples network latency, CPU utilization, committed
    memory utilization, and physical disk performance counters at a configurable
    interval. Results are written to timestamped CSV files for later analysis.

.PARAMETER Targets
    One or more DNS names or IP addresses to test with Test-Connection.

.PARAMETER OutputDirectory
    Directory where CSV files are written.

.PARAMETER IntervalSeconds
    Number of seconds between samples. Default: 5.

.PARAMETER DurationMinutes
    Optional runtime limit. If omitted or set to 0, the script runs until stopped.
#>

[CmdletBinding()]
param(
    [string[]]$Targets = @("1.1.1.1", "8.8.8.8"),
    [string]$OutputDirectory = (Join-Path $PWD "performance-logs"),
    [ValidateRange(1, 3600)]
    [int]$IntervalSeconds = 5,
    [ValidateRange(0, 525600)]
    [int]$DurationMinutes = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CounterValue {
    param([Parameter(Mandatory)][string]$CounterPath)

    try {
        $sample = Get-Counter -Counter $CounterPath -ErrorAction Stop
        [double]$sample.CounterSamples[0].CookedValue
    }
    catch {
        Write-Warning "Unable to read counter '$CounterPath': $($_.Exception.Message)"
        $null
    }
}

function Export-Metric {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][psobject]$InputObject
    )

    $InputObject | Export-Csv -Path $Path -NoTypeInformation -Append -Encoding UTF8
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$sessionStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$systemFile = Join-Path $OutputDirectory "system_$sessionStamp.csv"
$networkFile = Join-Path $OutputDirectory "network_$sessionStamp.csv"

$startTime = Get-Date
$endTime = if ($DurationMinutes -gt 0) { $startTime.AddMinutes($DurationMinutes) } else { $null }

Write-Host "Performance collection started."
Write-Host "Output directory: $OutputDirectory"
Write-Host "Interval: $IntervalSeconds second(s)"
if ($endTime) {
    Write-Host "Scheduled stop: $endTime"
}
else {
    Write-Host "Press Ctrl+C to stop."
}

while ($true) {
    $now = Get-Date

    if ($endTime -and $now -ge $endTime) {
        break
    }

    foreach ($target in $Targets) {
        $latencyMs = $null
        $status = "Timeout"

        try {
            $ping = Test-Connection -TargetName $target -Count 1 -ErrorAction Stop

            if ($ping) {
                if ($ping.PSObject.Properties.Name -contains "Latency") {
                    $latencyMs = [double]$ping.Latency
                }
                elseif ($ping.PSObject.Properties.Name -contains "ResponseTime") {
                    $latencyMs = [double]$ping.ResponseTime
                }
                $status = "Success"
            }
        }
        catch {
            $status = "Error"
        }

        Export-Metric -Path $networkFile -InputObject ([pscustomobject]@{
            Timestamp = $now.ToString("o")
            Target    = $target
            Status    = $status
            LatencyMs = $latencyMs
        })
    }

    $cpu = Get-CounterValue "\Processor(_Total)\% Processor Time"
    $memory = Get-CounterValue "\Memory\% Committed Bytes In Use"
    $diskRead = Get-CounterValue "\PhysicalDisk(_Total)\Avg. Disk sec/Read"
    $diskWrite = Get-CounterValue "\PhysicalDisk(_Total)\Avg. Disk sec/Write"
    $diskTransfers = Get-CounterValue "\PhysicalDisk(_Total)\Disk Transfers/sec"

    Export-Metric -Path $systemFile -InputObject ([pscustomobject]@{
        Timestamp        = $now.ToString("o")
        CPUPercent       = if ($null -ne $cpu) { [math]::Round($cpu, 2) } else { $null }
        MemoryPercent    = if ($null -ne $memory) { [math]::Round($memory, 2) } else { $null }
        DiskReadSeconds  = if ($null -ne $diskRead) { [math]::Round($diskRead, 6) } else { $null }
        DiskWriteSeconds = if ($null -ne $diskWrite) { [math]::Round($diskWrite, 6) } else { $null }
        DiskTransfersSec = if ($null -ne $diskTransfers) { [math]::Round($diskTransfers, 2) } else { $null }
    })

    Start-Sleep -Seconds $IntervalSeconds
}

Write-Host "Performance collection complete."
Write-Host "System metrics:  $systemFile"
Write-Host "Network metrics: $networkFile"
