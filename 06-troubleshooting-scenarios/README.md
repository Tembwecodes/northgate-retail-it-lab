What this is

A set of 9 real Tier 1/2 troubleshooting scenarios simulated and resolved on a dedicated spare VM (Win11-TroubleshootVM), built specifically for this project so faults could be safely simulated without touching the domain-joined lab used in the other projects. Each scenario follows the same pattern: reproduce or simulate the fault, diagnose the actual cause, fix it, and confirm the fix held.

What I built
A standalone workgroup VM (Win11-TroubleshootVM, machine name troubleshoot-pc), separate from the domain-joined Win11-Client used elsewhere in this repo, so faults could be simulated freely without risking other projects
9 completed troubleshooting scenarios, each simulating a distinct real-world Tier 1/2 fault and documented as a standalone ticket:
No internet access, stalled DHCP lease (HD-0154)
Websites won't load, DNS misconfiguration (HD-0155)
Application won't launch, broken shortcut requiring recreation (HD-0156)
Printer not responding, stopped Print Spooler service (HD-0157)
Slow performance, runaway process (HD-0158)
Login failure, corrupted user profile (HD-0159)
Shared drive access denied, NTFS Deny override (HD-0160)
Mapped network drive fails to reconnect after reboot (HD-0161)
Windows Update stuck, corrupted SoftwareDistribution folder (HD-0164)
No sound output, disabled audio device (HD-0165)
Tools

Windows 11, VirtualBox, Event Viewer, Device Manager, Task Manager, Services (services.msc), Registry Editor, PowerShell, icacls, ping/ipconfig

What broke, and how I fixed it

A tenth scenario (VPN connection failure) was planned but had to be dropped. Setting up RRAS on DC01 to act as a VPN server for the test failed consistently, both through the GUI wizard ("Cannot Continue — Internet Protocol (IP) is not installed") and via PowerShell (Install-RemoteAccess reporting the Remote Access role wasn't installed on the server), even after a full uninstall/reboot/reinstall cycle. Rather than keep fighting the lab environment itself, decided to skip the live VPN build and keep the project at 9 well-documented scenarios instead of forcing a tenth.

The mapped-network-drive scenario (HD-0161) also didn't reproduce cleanly. After extensive setup work (aligning NAT Network vs Internal Network between the VM and DC01, checking credential caching scope, DC01's network profile, and domain-qualified authentication), the drive kept reconnecting successfully after reboot rather than failing, the test share was permissive enough that even without perfectly cached credentials, the reconnect still worked. Documented that ticket based on the known general failure mechanisms for this class of issue instead of forcing an artificial repro.

The audio scenario (HD-0165) hit a smaller snag: trying to disable the audio device via a filtered PowerShell pipeline (Get-PnpDevice | Where-Object ... | Disable-PnpDevice) failed outright with a CIM/WMI error rather than disabling the device cleanly. Switched to disabling and re-enabling it directly through Device Manager instead, which worked reliably.

The login-failure scenario (HD-0159) needed an extra step beyond the obvious fix: after simulating profile corruption by renaming the account's ProfileList registry key, Windows created a new temporary profile key on the next login. Restoring the original key alone wasn't enough, the leftover temporary profile key also had to be deleted, and the ProfileList key itself needed an ownership change via Advanced Security Settings before it could even be renamed, since it's owned by SYSTEM/TrustedInstaller by default.

What I'd do differently next time
Test whether a shared drive's NTFS/share permissions are permissive enough to mask a reconnect fault before spending time on cross-VM network setup for that scenario
Try the Device Manager GUI route for PnP device state changes first, rather than a scripted pipeline call, when a quick toggle is all that's needed
Set aside a fixed time-box for environment-level blockers (like the RRAS/VPN setup) before deciding to document a scenario differently or drop it
Screenshots

(see /screenshots in this folder)

Resume-ready bullet

Simulated and resolved 9 real-world Tier 1/2 IT support incidents on a dedicated troubleshooting VM, covering network connectivity, DNS, application and printer faults, performance, user profile corruption, file-share permissions, and Windows Update failures, diagnosing genuine root causes using Event Viewer, Device Manager, and PowerShell rather than surface-level fixes.
