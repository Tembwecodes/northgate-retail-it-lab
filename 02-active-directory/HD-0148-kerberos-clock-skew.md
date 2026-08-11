# HD-0148: Authentication Failing Despite Correct Credentials (Kerberos Clock Skew)

**Category:** Head Office IT
**Priority:** Standard
**Status:** Resolved

## Summary

A user could log in locally but couldn't access domain resources, failing with a generic "Access is denied" and no obvious cause. Traced through elimination to Kerberos clock skew between the client and DC01.

## Problem

A domain user reported that local sign-in worked fine, but attempting to access a domain resource (a network share) failed with a generic access denied error. No permissions had recently changed on the resource in question.

## Discovery

Worked through the likely causes by elimination rather than guessing:

**Permissions** — checked NTFS and share permissions on the resource directly. Both were correctly configured for the user's group membership. Ruled out.

**DNS** — confirmed the client could resolve the DC and the resource host correctly, no stale records, no resolution failures. Ruled out.

**Time sync** — checked the client's system clock against DC01's. The client's clock had drifted noticeably outside Kerberos's default 5-minute tolerance window. Kerberos silently rejects ticket requests when the clock skew exceeds this tolerance, which produces exactly this kind of generic, unhelpful access-denied behaviour rather than a clear time-related error.

Confirmed via:

```
w32tm /stripchart /computer:DC01 /samples:5 /dataonly
```

Cross-checked Event Viewer on both the client and DC01 for Kerberos-related warnings (Event ID 4, "clock skew too great") to confirm this was genuinely the cause before acting on it, rather than assuming from the time difference alone.

## Fix

Resynced the client's clock against the DC:

```
w32tm /resync /force
```

Correcting the clock alone didn't immediately resolve access, a Kerberos ticket already issued and cached under the old, skewed time was still being presented and still failing. Cleared the cached tickets:

```
klist purge
```

## Verification

Retested resource access with the affected account. Access succeeded immediately after the ticket cache was cleared. Also tested with a known-good account throughout the diagnosis to confirm the issue was environmental (client-wide) rather than specific to the one user account.

## Root Cause

The client's system clock had drifted outside the 5-minute default tolerance Kerberos allows between a client and domain controller. Once outside that window, the DC silently refuses ticket requests rather than producing a clearly time-related error, surfacing instead as a generic access-denied on whatever resource was being requested.

## Resolution

- Resynced the client's clock against DC01 with `w32tm /resync /force`
- Cleared stale Kerberos tickets with `klist purge`, since a corrected clock doesn't retroactively invalidate tickets issued before the fix
- Verified resource access restored

## Lessons Learned

- The visible error rarely tells the whole story, "access is denied" here had nothing to do with actual permissions
- Troubleshooting by elimination (permissions, then DNS, then time) is more reliable than guessing from the symptom, even when it takes longer
- Kerberos time tolerance is a common, easy-to-overlook cause of authentication failures that look like permissions problems
- A root-cause fix doesn't always self-resolve everything downstream, cached state (in this case, Kerberos tickets) can need clearing separately even after the underlying cause is fixed
- Testing with a known-good account alongside the affected one helps confirm whether an issue is user-specific or environment-wide
