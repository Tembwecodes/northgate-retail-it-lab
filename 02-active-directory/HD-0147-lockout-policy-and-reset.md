# HD-0147: Account Lockout Policy Enforcement and Password Reset Workflow

**Category:** Head Office IT
**Priority:** Standard
**Status:** Resolved

## Summary

Built a domain-wide account lockout policy via GPO, which silently failed to save its settings on the first attempt. Once properly enforced, verified it end to end using a real lockout and Service Desk password reset scenario.

## Problem

Northgate Retail Group needed a domain-level account lockout policy, locking an account after repeated failed logins, as a baseline security control, plus a documented Service Desk workflow for resetting a locked-out user's password.

## Discovery 1: GPO settings don't save

Created a new GPO, "Password and Lockout Policy," linked at the domain root. Initially linked below the Default Domain Policy, checked link order and moved it to precede Default Domain Policy so it would take priority.

Configured the account lockout threshold, lockout duration, and reset counter under Computer Configuration → Policies → Windows Settings → Security Settings → Account Policies → Account Lockout Policy.

Tested against a client account by triggering repeated failed logins. No lockout occurred. Reopened the GPO to check, all three settings had reverted to **Not Defined**, despite appearing to save correctly at the time.

## Fix

Re-entered all three lockout settings a second time, saved, and this time ran a forced policy update on the client rather than waiting for the default refresh interval:

```
gpupdate /force
```

Reopened the GPO afterwards to confirm the settings had actually persisted this time (all three showing defined values, not "Not Defined").

## Verification

Retested with a domain user (jsmith), triggering the configured number of failed logins. The account locked as expected, confirmed via:

```
Get-ADUser jsmith -Properties LockedOut
```

`LockedOut: True`. Policy confirmed working end to end.

## Discovery 2: real-world lockout and reset

Some time later, user `ewilson` (HR) genuinely triggered the lockout policy through repeated failed logins. Used this as an opportunity to document the actual Service Desk response rather than just the policy test:

1. Verified the lockout in AD before touching anything:
   ```
   Get-ADUser ewilson -Properties LockedOut
   ```
   Confirmed `LockedOut: True`, establishing state before acting on it.

2. Reset the password via PowerShell, with a forced change at next logon so IT never actually knows the user's final password:
   ```
   Set-ADAccountPassword -Identity ewilson -Reset -NewPassword (ConvertTo-SecureString "TempPassw0rd!" -AsPlainText -Force)
   Set-ADUser -Identity ewilson -ChangePasswordAtLogon $true
   ```

3. Unlocked the account:
   ```
   Unlock-ADAccount -Identity ewilson
   ```

4. Verified end to end: the temporary password forced a mandatory change on first login, and the new password gave full access afterwards.

## Root Cause

GPO settings in the Account Lockout Policy node silently failed to persist on first save, a known quirk where certain security policy nodes need a second explicit save and a forced `gpupdate` to actually apply, rather than relying on the default background refresh.

## Resolution

- Re-applied and confirmed the lockout policy settings persisted correctly
- Forced policy application via `gpupdate /force` rather than waiting on it
- Verified with a synthetic test (jsmith) and later a genuine real-world lockout (ewilson), confirming both the policy and the reset workflow work correctly

## Lessons Learned

- Never trust a GPO setting saved without reopening the policy afterwards to confirm it actually persisted, some nodes are prone to silently reverting
- `gpupdate /force` is worth running immediately after any GPO change during testing, rather than waiting for the default refresh interval to rule out timing as a variable
- Verifying account state in AD before and after remediation (not just trusting the client-side error message) avoids acting on an assumption
- A forced password change at next logon keeps IT out of ever knowing a user's actual password, worth making standard practice for every reset
