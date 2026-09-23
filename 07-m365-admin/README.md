# Project 7: Microsoft 365 Administration Lab — Northgate Retail

## What this is
A cloud-only Microsoft 365 tenant built as if I'm the sole IT/cloud administrator for Northgate Retail Group, covering the same four departments as the rest of this series (Head Office IT, Finance, Human Resources, Store Ops). Originally scoped as a hybrid identity build syncing the 40-user on-prem AD domain from Project 2 into M365 via Azure AD Connect, but deliberately re-scoped mid-project to a cloud-only sandbox after hitting an unresolvable environment blocker (see below). The tenant runs on a Microsoft 365 E3 trial rather than the free Developer Program, after the Developer Program signup returned an undocumented "you don't currently qualify" rejection.

## What I built
- Microsoft 365 E3 trial tenant (Northgate Retail), provisioned after the Developer Program sandbox request was rejected with no explanation
- 12 cloud-only users across the four departments (Head Office IT x3, Finance x3, HR x2, Store Ops x4), each licensed with E3
- 4 shared mailboxes (IT Helpdesk, Finance, HR, Store Ops) via the Exchange admin center, with Full Access delegated to the relevant department's users
- 4 department-wide distribution lists (All-Head Office IT, All-Finance, All-HR, All-Store Ops), separate from the shared mailboxes
- Teams and channel structure: built on the tenant's auto-provisioned "Northgate Retail" Team, adding four Standard channels matching the four departments
- SharePoint document library structure: four department folders inside the Team's single shared library (Standard channels don't get their own site), each seeded with a sample working document
- A custom Conditional Access policy ("Require MFA for Head Office IT") on top of the tenant's 4 Microsoft-managed baseline policies, scoped to the three Head Office IT users
- Sign-in log review and a deliberate failed-login investigation, tracing a wrong-password attempt through to its Conditional Access evaluation result
- Identity Secure Score review (20.39%, 9 recommendations), with the two highest-priority items flagged as needing Entra ID P2
- Admin task scenarios: Helpdesk Administrator role assignment, a full licence remove-and-reassign cycle (simulating a leaver/starter handover), and an admin-initiated password reset with forced change at next logon

## Tools
Microsoft 365 admin center, Microsoft Entra admin center, Exchange admin center, Microsoft Teams, SharePoint, Conditional Access, Identity Secure Score, Microsoft Defender portal

## What broke, and how I fixed it
**The Developer Program sandbox rejected the signup outright.** Signed up with a new personal Microsoft account, correct profile, verified details, everything by the book. The dashboard returned "you don't currently qualify for a Microsoft 365 Developer Program sandbox subscription," a known but undocumented eligibility check with no visible criteria. Waited two full days in case it was a new-account cooldown (a documented common cause), no change. Rather than keep troubleshooting a system I had no visibility into, pivoted to a standard Microsoft 365 E3 trial instead, a completely different provisioning path, which worked immediately. Trade-off: E3 rather than the original E5/Developer target, meaning some advanced identity protection features (P2-tier risk-based Conditional Access) aren't available, documented as a deliberate scope adjustment rather than hidden.

**Azure AD Connect (Microsoft Entra Connect Sync) failed at the final configuration step.** After successfully connecting the on-prem northgateretail.local directory and configuring OU filtering to sync only the four department OUs, the install failed with "Microsoft Entra Connect could not configure application-based authentication for this server," traced via log to an MSAL AcquireTokenWithCertificate failure. Persisted after a clean retry. Root cause suspected to be the newer mandatory Application-Based Authentication feature's certificate fallback not completing cleanly inside a nested VirtualBox VM with no TPM, an environment limitation, not a configuration mistake. Rather than keep sinking hours into a blocker specific to running Windows Server nested inside VirtualBox (which has nothing to do with the M365 admin skills the project is meant to demonstrate), made the call to drop the hybrid sync entirely and rebuild the remaining scope as a cloud-only M365 admin lab. This is the same "know when to stop troubleshooting an environment quirk" lesson as the dropped VPN scenario in Project 6.

**Licence assignment isn't available from the Entra admin center anymore.** Tried to assign an E3 licence to a new user directly from their Entra ID profile's Licenses page, it's now read-only, with a banner redirecting to the M365 admin center specifically. Licensing now lives in one console, user creation in another, worth knowing before assuming everything's reachable from a single admin surface.

**Conditional Access results on a failed sign-in showed "Not applicable," which looked wrong at first.** A deliberately triggered failed login (wrong password, three attempts) showed every Conditional Access policy as "Not applicable" in its sign-in log detail, including the custom MFA policy that should have applied to that user. This isn't a fault: Conditional Access only evaluates after a successful password check, so a sign-in that fails at the password stage never reaches CA policy evaluation at all. Confirmed this was correct behaviour rather than a misconfiguration by checking Microsoft's own documentation on the CA evaluation flow.

**Risky sign-ins showed no results for the failed login attempts.** Expected the deliberately failed sign-ins to show up under Risky sign-ins for investigation. They didn't. Traced this to Identity Protection's risk engine needing signals like impossible travel or anonymous IP addresses, repeated wrong passwords from a known, consistent IP don't register as anomalous. Confirmed via Identity Secure Score, which separately flagged "Protect all users with a sign-in risk policy" as a P2-gated recommendation this E3 tenant doesn't have access to.

## What I'd do differently next time
- Try the standard E3/E5 trial signup route first, rather than assuming the free Developer Program is always the fastest path in
- Budget a fixed time limit for infrastructure-specific blockers (like the AD Connect certificate failure) before attempting a fix, and set the cutoff for "pivot scope" earlier rather than after a full troubleshooting cycle
- Check which admin console owns a given task (users vs. licensing vs. mailboxes) before assuming one portal does everything
- When reading sign-in logs for the first time, check what Conditional Access does and doesn't evaluate before treating an unexpected "Not applicable" as a bug

## Screenshots
(see /screenshots in this folder)
- M365 E3 tenant overview and licence count
- 12 users created across the four departments with E3 licences assigned
- Shared mailbox Full Access delegation (IT Helpdesk)
- Teams channel structure (Head Office IT, Finance, HR, Store Ops)
- SharePoint department folders with sample documents
- Custom Conditional Access policy configuration and creation confirmation
- Sign-in log detail showing MFA enforcement ("MFA requirement satisfied by claim in the token")
- Sign-in log Conditional Access tab showing "Not applicable" on a failed sign-in
- Identity Secure Score recommendations list
- Helpdesk Administrator role assignment
- Licence removal and reassignment confirmation
- Password reset confirmation

## Resume-ready bullet
Built a cloud-only Microsoft 365 environment for a simulated retail business after pivoting away from a blocked hybrid identity sync, covering 12 licensed users, Exchange shared mailboxes and distribution lists, Teams and SharePoint structure across four departments, a custom Conditional Access MFA policy verified through real sign-in log evidence, Identity Secure Score review, and admin tasks including role assignment, licence lifecycle management, and password resets.
