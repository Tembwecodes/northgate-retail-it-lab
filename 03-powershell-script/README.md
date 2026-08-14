# 03 - PowerShell Diagnostics Script

Part of the [Northgate Retail Group IT Support Home Lab](../README.md) portfolio series.

## Overview

A PowerShell script that automates a real Tier 1/2 support task: gathering system info, checking network status, and restarting the Print Spooler service, with full error handling and logging to a timestamped file. Built to simulate the kind of diagnostic checks a Service Desk technician would run repeatedly across tickets, rather than doing each one manually every time.

## What it does

- **System info:** hostname, OS build, uptime, C: drive free space
- **Network status:** default gateway reachability, DNS resolution against `northgateretail.local`
- **Print Spooler:** checks service status, restarts automatically if not running
- **Event log summary:** pulls the last 24 hours of System log errors and warnings

Every section is wrapped in try/catch, so one failed check (e.g. no gateway) doesn't stop the rest of the script running. All output is logged with INFO/WARN/ERROR levels to `C:\Logs\Northgate-Diagnostics\diagnostic-<timestamp>.log`, so it can be attached to a ticket as evidence rather than just read off the console.

## Tools

PowerShell 5.1, Windows Task Scheduler (optional automation), VirtualBox shared folders, VirtualBox Guest Additions

## Setup steps

1. Copy `Northgate-Diagnostics.ps1` onto the target machine
2. Open PowerShell as Administrator
3. Allow the script to run for this session:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope Process -Force
   ```
4. Run it:
   ```powershell
   .\Northgate-Diagnostics.ps1
   ```
5. (Optional) Schedule it to run daily:
   ```powershell
   $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Northgate-Diagnostics.ps1"
   $Trigger = New-ScheduledTaskTrigger -Daily -At 8am
   Register-ScheduledTask -TaskName "Northgate Daily Diagnostics" -Action $Action -Trigger $Trigger -RunLevel Highest
   ```

## What broke along the way

Getting the script from the host machine onto the isolated lab VM (Win11-Client) turned into its own troubleshooting exercise:

- Set up a VirtualBox shared folder pointing at a host directory, but it wouldn't mount
- Root cause: VirtualBox Guest Additions were never installed on this VM, so there was no driver support for shared folders
- Installed Guest Additions via a second virtual optical drive (the runtime Devices menu wasn't reachable in this session), rebooted, and confirmed the share mounted successfully at `\\VBOXSVR\Computer_application`
- Copied the script across and ran it cleanly

Once running, the script's gateway check failed, this VM's NAT Network config has no default gateway to reach, which is a known limitation of this lab environment rather than a bug in the script.

## What I'd do differently

- Install Guest Additions as a standard step when first building any new VM, rather than discovering the gap only when shared folders are needed
- Harden the gateway check with a fallback ping to a known-good host (e.g. the DC) so it degrades gracefully on NAT Network configs without a gateway
- Implement the Task Scheduler automation as a live scheduled task rather than just documenting the command

## Screenshots

See `screenshots/` for the console output and log file contents from a full run.

## Ticket writeup

See [HD-0149](../tickets/HD-0149.md) for the full incident writeup.
