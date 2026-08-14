<#
.SYNOPSIS
    Northgate Retail Group - IT Support Diagnostic Script

.DESCRIPTION
    Simulates a real Tier 1/2 support script: gathers system info, checks
    network connectivity, restarts the Print Spooler service, and logs
    everything to a timestamped log file for later review or attaching
    to a ticket.

.NOTES
    Author: Liam
    Project: 03-powershell-script (Northgate Retail Group home lab)
    Run as: Administrator (required for spooler restart)
#>

# ---- Setup ----
$LogFolder = "C:\Logs\Northgate-Diagnostics"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile   = Join-Path $LogFolder "diagnostic-$Timestamp.log"

if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $Line
    Add-Content -Path $LogFile -Value $Line
}

Write-Log "===== Northgate Diagnostics started on $env:COMPUTERNAME ====="

# ---- 1. System info ----
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $uptime = (Get-Date) - $os.LastBootUpTime

    Write-Log "Computer: $($cs.Name) | Model: $($cs.Model)"
    Write-Log "OS: $($os.Caption) | Build: $($os.BuildNumber)"
    Write-Log ("Uptime: {0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $totalGB = [math]::Round($disk.Size / 1GB, 1)
    Write-Log "C: drive free space: $freeGB GB / $totalGB GB"
}
catch {
    Write-Log "Failed to gather system info: $($_.Exception.Message)" "ERROR"
}

# ---- 2. Network status ----
try {
    $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop | Select-Object -First 1).NextHop
    $gatewayTest = Test-Connection -ComputerName $gateway -Count 2 -Quiet -ErrorAction Stop

    if ($gatewayTest) {
        Write-Log "Gateway ($gateway) reachable"
    } else {
        Write-Log "Gateway ($gateway) NOT reachable" "WARN"
    }
}
catch {
    Write-Log "Gateway check failed: $($_.Exception.Message)" "ERROR"
}

try {
    $dnsTest = Resolve-DnsName -Name "northgateretail.local" -ErrorAction Stop
    Write-Log "DNS resolution OK for northgateretail.local ($($dnsTest[0].IPAddress))"
}
catch {
    Write-Log "DNS resolution FAILED for northgateretail.local: $($_.Exception.Message)" "ERROR"
}

# ---- 3. Print Spooler check/restart ----
try {
    $spooler = Get-Service -Name Spooler -ErrorAction Stop

    if ($spooler.Status -ne "Running") {
        Write-Log "Spooler service is $($spooler.Status). Attempting restart..." "WARN"
        Restart-Service -Name Spooler -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        $spooler.Refresh()
        Write-Log "Spooler service status after restart: $($spooler.Status)"
    } else {
        Write-Log "Spooler service is running normally"
    }
}
catch {
    Write-Log "Print Spooler check/restart failed: $($_.Exception.Message)" "ERROR"
}

# ---- 4. Recent system errors (last 24h) ----
try {
    $recentErrors = Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        Level     = 2,3   # 2 = Error, 3 = Warning
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction Stop

    Write-Log "Found $($recentErrors.Count) System log errors/warnings in the last 24 hours"

    $recentErrors | Select-Object -First 10 TimeCreated, Id, LevelDisplayName, Message |
        Format-Table -AutoSize | Out-String | Add-Content -Path $LogFile
}
catch [Exception] {
    if ($_.Exception.Message -like "*No events were found*") {
        Write-Log "No System log errors/warnings in the last 24 hours"
    } else {
        Write-Log "Failed to query System event log: $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "===== Northgate Diagnostics completed. Log saved to $LogFile ====="
