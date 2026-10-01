<#
.SYNOPSIS
    Collects a concise Windows system health snapshot.

.DESCRIPTION
    Reports operating system, uptime, memory, disk capacity, network adapters,
    and selected service state in a structured object suitable for console,
    JSON, or automation use.

.PARAMETER OutputJson
    Optional path for JSON output.

.EXAMPLE
    .\scripts\Get-SystemHealth.ps1

.EXAMPLE
    .\scripts\Get-SystemHealth.ps1 -OutputJson .\reports\system-health.json
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem

$boot = $os.LastBootUpTime
$uptime = (Get-Date) - $boot

$disks = @(
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    ForEach-Object {
        [pscustomobject]@{
            DeviceId   = $_.DeviceID
            SizeGB     = [math]::Round($_.Size / 1GB, 2)
            FreeGB     = [math]::Round($_.FreeSpace / 1GB, 2)
            FreePct    = if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { 0 }
        }
    }
)

$adapters = @(
    Get-NetAdapter -ErrorAction SilentlyContinue |
    Where-Object Status -eq "Up" |
    Select-Object Name, InterfaceDescription, LinkSpeed, MacAddress
)

$services = @(
    "Dnscache",
    "Winmgmt",
    "EventLog"
) | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    if ($svc) {
        [pscustomobject]@{
            Name   = $svc.Name
            Status = $svc.Status.ToString()
        }
    }
}

$report = [pscustomobject]@{
    ComputerName = $env:COMPUTERNAME
    Manufacturer = $computer.Manufacturer
    Model        = $computer.Model
    OperatingSystem = $os.Caption
    OSVersion    = $os.Version
    LastBoot     = $boot
    UptimeHours  = [math]::Round($uptime.TotalHours, 1)
    Memory = [pscustomobject]@{
        TotalGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        FreeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    }
    Disks        = $disks
    ActiveAdapters = $adapters
    CoreServices = $services
    CollectedAt  = (Get-Date).ToUniversalTime().ToString("o")
}

$report

if ($OutputJson) {
    $parent = Split-Path -Parent $OutputJson
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputJson -Encoding UTF8
    Write-Information "JSON report written to $OutputJson"
}
