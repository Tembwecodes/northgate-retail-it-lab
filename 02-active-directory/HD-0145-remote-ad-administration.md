# HD-0145: Remote Active Directory Administration from a Client Workstation

**Category:** Head Office IT
**Priority:** Standard
**Status:** Resolved

## Summary

Needed to demonstrate remote AD administration from Win11-Client, without RSAT installed locally. What started as a straightforward RSAT install turned into a genuinely useful troubleshooting exercise once the client's isolated network and DC01's hostname mismatch both got in the way.

## Problem

RSAT (Active Directory tools) needed installing on Win11-Client so admin tasks could be run against the domain without hopping onto the DC directly.

## Discovery 1: RSAT install fails, no internet route

Running `Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0` failed with a COMException. Checked connectivity:

```
Test-NetConnection -ComputerName 8.8.8.8 -Port 443
```

Both `PingSucceeded` and `TcpTestSucceeded` came back `False`. Win11-Client sits on an isolated lab network with no route out, so `Add-WindowsCapability -Online` was never going to work here. This is a genuine constraint of the lab environment, not a misconfiguration.

## Pivot: PowerShell remoting instead of RSAT

Rather than mount an ISO for an offline RSAT install, decided to demonstrate remote AD administration via PowerShell remoting instead. This is arguably closer to how real Service Desk/sysadmin work happens anyway, most day-to-day AD admin from a technician's workstation is done via `Enter-PSSession`/`Invoke-Command` into a DC or jump box, not a local RSAT GUI.

## Discovery 2: WinRM confirmed, but Enter-PSSession hangs silently

On DC01, confirmed WinRM was already running:

```
Get-Service WinRM
```

`Status: Running`. Ran `Enable-PSRemoting -Force` to be sure remoting was fully configured, completed cleanly with no prompts, confirming it was already set up correctly (typical for a DC).

Back on Win11-Client, ran:

```
Enter-PSSession -ComputerName DC01 -Credential NORTHGATERETAIL\Administrator
```

No credential prompt appeared, no error, just a hanging blank prompt. Opened a second tab and tested directly:

```
Test-NetConnection -ComputerName DC01 -Port 5985
```

Result: `WARNING: Name resolution of DC01 failed`. The DC's actual Windows computer name had never been changed from its post-promotion default, `WIN-FP8CEDR9FMR`, despite the VirtualBox VM being labelled `WinServer2022-DC01`. "DC01" only existed as a mental label, not a resolvable hostname.

## Discovery 3: connecting by IP isn't a real fix

As a quick check, connected by IP instead:

```
Test-NetConnection -ComputerName 192.168.10.1 -Port 5985
```

This succeeded (`TcpTestSucceeded: True`), confirming WinRM itself was reachable. But attempting `Enter-PSSession` against the raw IP failed with:

```
The WinRM client cannot process the request. Default authentication may be used with an IP address under the following conditions: the transport is HTTPS or the destination is in the TrustedHosts list...
```

On a domain, `Enter-PSSession` defaults to Kerberos authentication, which doesn't work against a bare IP address, only a proper hostname. Confirmed the name resolution failure was the real root cause, not just an inconvenience to route around.

## Fix: rename DC01 to match its intended identity

On DC01:

```
Rename-Computer -NewName "DC01" -Restart
```

After the reboot, confirmed the rename:

```
hostname
DC01
```

## Verification

From Win11-Client:

```
Enter-PSSession -ComputerName DC01 -Credential NORTHGATERETAIL\Administrator
```

Credential prompt appeared, authenticated successfully, prompt changed to `[DC01]: PS C:\Users\Administrator.WIN-FP8CEDR9FMR\Documents>`, confirming a genuine remote session (not a loopback on DC01 itself, confirmed by checking the VirtualBox window title bar throughout).

Ran a live AD query from inside the session to prove it:

```
Get-ADUser -Filter * | Select-Object Name | Select-Object -First 5
```

Returned Administrator, Guest, krbtgt, John Smith, Sarah Jones, pulled entirely through the remote session.

## Extending the scenario: create user and reset password remotely

Still inside the `[DC01]:` session from Win11-Client:

```
New-ADUser -Name "Test Remote" -SamAccountName "tremote" -GivenName "Test" -Surname "Remote" -AccountPassword (ConvertTo-SecureString "Passw0rd123!" -AsPlainText -Force) -Enabled $true -Path "OU=Head Office IT,DC=northgateretail,DC=local"
```

Verified with `Get-ADUser -Identity tremote -Properties *`, confirmed the account existed with the correct creation timestamp.

Then reset the password and forced a change at next logon, matching the convention used for other lab accounts:

```
Set-ADAccountPassword -Identity tremote -Reset -NewPassword (ConvertTo-SecureString "NewPassw0rd456!" -AsPlainText -Force)
Set-ADUser -Identity tremote -ChangePasswordAtLogon $true
```

Both completed cleanly.

## Root Cause

1. Win11-Client has no internet access on the isolated lab network, ruling out online RSAT install.
2. DC01's Windows hostname was never set to match its intended identity after the fresh AD DS promotion, breaking name resolution for `DC01`.
3. Kerberos authentication (the domain default) doesn't work against a raw IP address, so the hostname mismatch had to be properly fixed rather than worked around.

## Resolution

- Renamed DC01's local hostname to match its intended identity (`Rename-Computer -NewName "DC01" -Restart`)
- Verified genuine remote PowerShell session from Win11-Client into DC01 over Kerberos
- Demonstrated remote AD administration end to end: querying users, creating a new account, and resetting a password, all without RSAT installed on the client

## Lessons Learned

- An "offline" lab network is a legitimate constraint worth documenting, not just a blocker to work around
- A silently hanging `Enter-PSSession` with no error is very often a name resolution problem, worth testing with `Test-NetConnection` before assuming it's a firewall or credential issue
- Connecting by IP is not a drop-in substitute for hostname on a domain, Kerberos needs a proper name
- Always double check which VM window a command is actually running in, especially when a "remote" session can just as easily be a loopback if you're already on the target machine
