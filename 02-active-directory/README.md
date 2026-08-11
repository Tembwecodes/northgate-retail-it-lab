# Project 2: Active Directory Lab — Northgate Retail Group

## What this is

A domain environment for Northgate Retail Group, built as if I'm the sole IT support tech responsible for user accounts, permissions, and access policy across a Head Office and Store Ops locations. Two VMs in VirtualBox: a domain controller and a domain-joined client, deliberately isolated with no internet access to mirror a locked-down corporate network.

## What I built

- Fresh AD DS/DNS promotion for `northgateretail.local` on WinServer2022-DC01 (Server Core, static IP)
- 4 OUs matching the four Project 1 ticketing categories: Head Office IT, Finance, Human Resources, Store Ops
- 40 user accounts across those OUs (7, 7, 5, 21), each with a forced password change at next logon
- Win11-Client domain-joined and verified with a real domain login
- IT-Support security group with matching NTFS and share permissions on a restricted file share
- A Password and Lockout Policy GPO enforced at domain level
- A remote AD administration workflow via PowerShell remoting, no RSAT installed on the client

## Tools

VirtualBox, Windows Server 2022, Windows 11, Active Directory Domain Services, DNS, Group Policy, PowerShell, ADUC

## What broke, and how I fixed it

**Wrong role installed first.** Went to install AD DS and installed AD CS (Certificate Services) instead on the first attempt. Caught it before promoting, removed the role, and installed AD DS correctly. The AD DS promotion wizard's prerequisites check then failed anyway because the leftover AD CS role was still blocking it, had to remove that fully before the check would pass.

**DC01's hostname never matched its identity.** After a fresh promotion, DC01's actual Windows computer name stayed at its post-install default (`WIN-FP8CEDR9FMR`) rather than becoming `DC01`, the VirtualBox VM label and my own documentation called it DC01, but nothing in Windows itself did. This caused two separate downstream failures before I caught the actual cause:
- A file share scenario where hostname-based access behaved inconsistently until I renamed the machine and cleared cached Kerberos tickets on the client
- Later, a remote PowerShell session (`Enter-PSSession -ComputerName DC01`) that hung silently with no error at all. Diagnosed with `Test-NetConnection`, which returned a clean "Name resolution of DC01 failed", confirming DC01 simply didn't exist as a resolvable name. Fixed properly with `Rename-Computer -NewName "DC01" -Restart`, rather than working around it.

**Connecting by IP isn't a substitute for a hostname on a domain.** As a quick workaround for the above, tried connecting by IP address instead of hostname. That got further (WinRM was reachable) but failed with a Kerberos authentication error, domain auth defaults to Kerberos, which doesn't authenticate against a bare IP. This confirmed the hostname fix was the real solution, not a nice-to-have.

**RSAT couldn't install on the client.** `Add-WindowsCapability -Online` failed outright. Turned out Win11-Client genuinely has no internet route out on this isolated network (confirmed with `Test-NetConnection -ComputerName 8.8.8.8 -Port 443`, both ping and TCP failed). Rather than mount an offline ISO source for DISM, pivoted to PowerShell remoting into the DC instead, arguably a more realistic reflection of how technicians actually administer AD day to day.

**GPO lockout settings silently failed to save.** The account lockout threshold, duration, and reset counter all stayed "Not Defined" after configuring them in the GPO editor the first time. Had to re-set them and force a `gpupdate /force` on the client before lockout actually triggered in testing.

## What I'd do differently next time

- Double-check the server role selected against the confirmation screen before clicking Install, rather than assuming the first item in the list is the right one
- Set the DC's hostname correctly at promotion time, not after, it caused two separate issues later that both traced back to the same root cause
- Script the 40-user creation rather than doing it all through the ADUC GUI, worth revisiting in Project 3 (PowerShell scripting)
- Verify GPO settings actually saved (reopen the policy and check) immediately after configuring them, rather than assuming a clean save and finding out during testing

## Screenshots

(see /screenshots in this folder)

- OU structure in ADUC showing all four departments
- 40-user count verified against target
- IT-Support-Share NTFS and share permissions
- Remote PowerShell session into DC01 from Win11-Client, prompt showing `[DC01]:`
- `Get-ADUser` output confirming a user created entirely through the remote session

## Resume-ready bullet

Designed and built a 40-user Active Directory environment for a simulated retail business, covering OU structure, group-based NTFS/share permissions, GPO-enforced account lockout policy, and remote AD administration via PowerShell, diagnosing and resolving genuine infrastructure faults (role misconfiguration, hostname/Kerberos authentication failures, isolated-network constraints) along the way.
