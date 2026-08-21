# Northgate Retail Group — IT Knowledge Base

Internal Tier 1 knowledge base covering common issues across Head Office IT, Finance, Human Resources, and Store Ops. Each article follows the same symptom-to-resolution format so any Tier 1 tech (or a self-service user) can work through it without prior context.

This first batch of 10 articles is drawn directly from scenarios actually run in the lab (Projects 1-4). More will be added once Project 7 (M365 Admin) is built, since several other common issues (MFA, Outlook sync, etc.) depend on a mailbox/tenant existing first.

---

## KB-0001: User locked out of account

**Category:** Account/Access
**Affected users:** All OUs
**Symptom:** User reports they can't log in, gets an "account has been locked" message, or repeated failed logon attempts show in Event Viewer.
**Cause:** Account lockout policy triggers after a set number of failed logon attempts. In the ewilson case this was genuine repeated failed logins rather than a stuck cached credential.
**Resolution:**
1. Confirm identity with the user before touching the account.
2. In ADUC, right-click the user > Unlock account.
3. Reset the password: right-click > Reset Password, set a temporary password, tick "User must change password at next logon".
4. Have the user log in and confirm they're prompted to set a new password.
5. If lockouts keep recurring, check for other devices (phone, mapped drives) still retrying an old cached password.
**Escalate if:** Lockouts keep recurring within minutes of unlocking.

Related: HD-0142, HD-0147

---

## KB-0002: "Access denied" on shared drive

**Category:** Account/Access
**Affected users:** All OUs (originally built around Head Office IT)
**Symptom:** User can see a shared folder but gets "Access is denied" opening it, or the folder doesn't appear at all.
**Cause:** In the IT-Support-Share scenario, this came down to NTFS and share permissions both needing to be scoped to the IT-Support security group, not just one or the other.
**Resolution:**
1. Check both NTFS and share permissions on the folder in Properties > Security / Sharing.
2. In ADUC, confirm the user is a member of the group the permissions reference (e.g. IT-Support).
3. Add them to the group if missing, then have them log off/on to refresh their token.
4. Re-test access.
**Escalate if:** The user is already in the correct group and still can't access it, this points to a permissions inheritance issue on the folder's ACL itself, which is what actually happened here and needed a proper NTFS fix rather than a group membership fix.

Related: IT-Support-Share NTFS + share permissions scenario (Project 2)

---

## KB-0003: DNS not resolving

**Category:** Network
**Affected users:** All OUs
**Symptom:** User reports "no internet" or can't reach a specific internal resource, but other network activity still works.
**Cause:** In the real case this was a broken/missing CNAME record, not a client-side fault.
**Resolution:**
1. Check basic connectivity: `ping 8.8.8.8` (raw connectivity) vs `ping google.com` or the internal hostname (DNS).
2. If IP ping works but name resolution fails, run `nslookup` against the DNS server to check the record.
3. Flush the client's DNS cache: `ipconfig /flushdns`.
4. If the record itself is wrong or missing on the DNS server, correct/recreate it there rather than troubleshooting further on the client.
5. Re-test from the client.
**Escalate if:** Multiple users report the same failure at once.

Related: HD-0144

---

## KB-0004: Remote session (RDP) won't connect

**Category:** Network
**Affected users:** All OUs
**Symptom:** Technician can't establish an RDP session to a user's machine, connection times out or is refused.
**Cause:** Typically Remote Desktop not enabled on the target, or the firewall blocking port 3389.
**Resolution:**
1. Confirm the target machine is powered on and connected to the network.
2. Check Remote Desktop is enabled in System Properties on the target.
3. Confirm port 3389 isn't blocked by the firewall.
4. Retry the connection and confirm control works before starting the actual fix.
**Escalate if:** The machine is confirmed online but still unreachable.

Related: HD-0143

---

## KB-0005: Wrong default printer set

**Category:** Printing
**Affected users:** Human Resources
**Symptom:** User's print jobs come out at the wrong printer.
**Cause:** Default printer setting had changed and Windows was set to manage the default automatically, overriding the intended one.
**Resolution:**
1. Open Settings > Bluetooth & devices > Printers & scanners.
2. Turn off "Let Windows manage my default printer".
3. Select the correct printer and click Set as default.
4. Print a test page to confirm.
**Escalate if:** The correct printer doesn't appear in the list at all.

Related: HD-0153

---

## KB-0006: Print jobs stuck in the queue

**Category:** Printing
**Affected users:** All OUs
**Symptom:** Documents stay "Pending" or "Printing" indefinitely and nothing new will print until the queue clears.
**Cause:** A stalled Print Spooler service, the same fault class covered by the Print Spooler check built into Northgate-Diagnostics.ps1.
**Resolution:**
1. Try cancelling the stuck job manually first.
2. If it won't clear, restart the Print Spooler service: `net stop spooler` then `net start spooler`.
3. Check the spooler folder (`C:\Windows\System32\spool\PRINTERS`) is empty afterwards, manually delete any leftover files if not.
4. Re-send the print job.
**Escalate if:** The spooler keeps stalling repeatedly on the same machine.

Related: printer troubleshooting via GPO/IP printing (Project 2), Northgate-Diagnostics.ps1

---

## KB-0007: Can't find/connect to a networked printer

**Category:** Printing
**Affected users:** All OUs
**Symptom:** Printer doesn't show up when searching to add it, or an existing printer shows as offline.
**Cause:** In the Project 2 case this traced back to IP printing configuration rather than the printer itself being faulty.
**Resolution:**
1. Confirm the printer is powered on and shows a network connection.
2. From the client, try browsing to the print server directly: `\\printserver\printername`.
3. If that fails, ping the printer's IP directly to isolate whether it's a network-layer issue.
4. Re-add the printer via Settings > Printers & scanners > Add device, using IP printing if the print server route continues to fail.
**Escalate if:** The printer is confirmed reachable by IP but still won't add through the print server.

Related: GPO/IP printing troubleshooting (Project 2)

---

## KB-0008: External monitor not detected

**Category:** Hardware/Display
**Affected users:** Head Office IT
**Symptom:** Laptop connected to an external monitor after a monitor swap shows nothing on the second screen.
**Cause:** Windows hadn't picked up the display change after the physical swap.
**Resolution:**
1. Check the cable is fully seated at both ends and try a different port/cable if available.
2. Confirm the monitor is on the correct input source.
3. In Windows, go to Settings > System > Display and click Detect.
4. Use Win+P to cycle through display modes in case it's set to "PC screen only".
**Escalate if:** The monitor works fine with a different machine.

Related: HD-0151

---

## KB-0009: New starter software install

**Category:** Software
**Affected users:** Store Ops
**Symptom:** New starter needs a required application installed on their machine before they can begin work.
**Cause:** Standard new-starter provisioning gap, not a fault, but handled remotely since Store Ops sites aren't staffed with on-site IT.
**Resolution:**
1. Confirm with the user (or their manager) exactly which application and version is required.
2. Establish a remote session (RDP or TeamViewer, whichever the site supports).
3. Install the application, applying any standard configuration Northgate expects for that role.
4. Launch the application once to confirm it opens cleanly and the user can log in/access what they need.
5. Talk the user through where to find it and confirm they're happy before ending the session.
**Escalate if:** The install requires licensing or admin rights beyond what Tier 1 can provision.

Related: HD-0150

---

## KB-0010: Missing or moved file recovery

**Category:** Software
**Affected users:** Finance
**Symptom:** User reports a file they were working on has disappeared or isn't where they expect it to be.
**Cause:** Files moved or misplaced during normal use, most often into the wrong folder or a hidden view/filter hiding it rather than genuine deletion.
**Resolution:**
1. Confirm with the user exactly where the file was last saved and its expected name.
2. Check File Explorer's search across the likely drive/folder, including subfolders.
3. Check the Recycle Bin in case it was deleted rather than moved.
4. If it's on a shared/network drive, check File History or previous versions (right-click folder > Properties > Previous Versions) if enabled.
5. Once located, confirm the user can open it and knows where it ended up.
**Escalate if:** The file can't be found anywhere and previous versions aren't available, this needs a backup restore request rather than further local searching.

Related: HD-0152

---
