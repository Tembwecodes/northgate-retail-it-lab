# HD-0146: AD DS Role Installation Mixup During Domain Promotion

**Category:** Head Office IT
**Priority:** Standard
**Status:** Resolved

## Summary

Installed the wrong server role on the first attempt at standing up DC01 as a domain controller, Active Directory Certificate Services instead of Active Directory Domain Services. Caught before promotion completed, but the leftover role then blocked the actual AD DS promotion until fully removed.

## Problem

Needed to promote WinServer2022-DC01 to a domain controller for `northgateretail.local` as the starting point for the whole AD lab.

## Discovery

Went through Server Manager's Add Roles and Features wizard and selected a certificate-related role by mistake, AD CS (Active Directory Certificate Services) rather than AD DS (Active Directory Domain Services). Didn't catch it until reviewing the Confirmation screen, which showed AD CS-specific components rather than the expected AD DS, Group Policy Management, and RSAT tools.

Removed the AD CS role and installed AD DS correctly, this time double-checking the Confirmation screen listed AD DS, Group Policy Management, and RSAT before proceeding.

Ran the AD DS Configuration Wizard to promote the server. The Prerequisites Check failed. The leftover AD CS installation, despite being what I thought was a clean removal, was still present enough to block domain controller promotion outright.

## Fix

Went back into Server Manager and fully removed AD CS via Remove Roles and Features, this time confirming it showed a clean `Roles: 0` on the Local Server dashboard afterwards, rather than assuming the first removal had worked.

Re-ran the AD DS Configuration Wizard. Prerequisites Check passed cleanly this time, proceeded through to Install.

## Verification

Confirmed successful promotion by logging in as `NORTHGATERETAIL\Administrator` and checking Server Manager, which showed AD DS and DNS roles installed and healthy. Cross-checked with:

```
Get-ADDomain
```

Returned `NetBIOSName: NORTHGATERETAIL`, `DomainMode: Windows2016Domain`, confirming a clean, correctly promoted forest.

## Root Cause

Selected the wrong role in the Add Roles and Features wizard, the certificate services role name and description look similar enough to domain services at a glance to make this an easy mistake under time pressure, and a partial/incomplete removal of that wrong role was enough to fail the subsequent prerequisites check for the correct one.

## Resolution

- Fully removed the AD CS role (confirmed via `Roles: 0` on Local Server, not just the removal wizard completing)
- Reinstalled and promoted AD DS successfully for `northgateretail.local`

## Lessons Learned

- Always check the Confirmation screen against what you actually intended to install before clicking Install, not just skimming past it
- A role removal completing without error doesn't guarantee every dependency or artifact is fully gone, worth confirming a clean state afterwards (e.g. `Roles: 0`) rather than assuming
- Prerequisites check failures with a vague reason are worth investigating for leftover roles/features, not just retried blindly
