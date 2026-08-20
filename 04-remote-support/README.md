# Project 4: Remote Support (TeamViewer)

## What this is
A remote support simulation for Northgate Retail Group, where a host machine
acts as the technician and the isolated Win11-Client VM plays the end user.
Four tickets were worked end to end, one per Head Office department, each
following a realistic pattern: reproduce the fault as the "user," connect
remotely, diagnose, fix, and confirm.

## What I built
- A second NAT network adapter added to Win11-Client (alongside its existing
  intnet adapter to DC01) to give it an internet route without disturbing its
  domain connection
- TeamViewer installed on both the host (technician) and Win11-Client (end
  user), connected via session code with end-user verification
- Four support scenarios, each simulating the fault first and then fixing it
  live over the remote session:
  1. **Store Ops** – installed 7-Zip for a new starter, confirmed shell
     integration, pinned it to the taskbar
  2. **Head Office IT** – broke display resolution/scaling after a simulated
     monitor swap, diagnosed the cause as the generic Microsoft Basic Display
     Adapter (confirmed via Windows Update: no better driver available),
     restored scaling to recommended
  3. **Finance** – simulated a moved/renamed file, found that content search
     failed due to fresh-VM indexing lag, recovered the file by sorting
     Documents by Date Modified instead
  4. **Human Resources** – added a second (PCL6) printer, broke the default
     printer via Windows' auto-management setting, restored the correct
     default and disabled auto-management to stop it recurring

## Tools
TeamViewer, VirtualBox networking (NAT adapter), Windows Settings
(Display, Printers & Scanners), File Explorer

## What broke, and how I fixed it
**TeamViewer's own download page kept redirecting.** Clicking "Download"
routed through Bing search results and a Business trial signup/shopping cart
flow instead of the actual installer. Fixed by going straight to the direct
installer URL rather than following the marketing pages.

**Newer TeamViewer hides the "Control Remote Computer" panel behind sign-in.**
The ID/password-only view has no Partner ID field until you're signed into a
free account. Signed in on the host side and used the session-code flow
instead.

**Display resolution dropdown was locked during the remote session.**
Couldn't change it directly through Settings while connected. Diagnosed via
Advanced Display that Win11-Client was running the generic Microsoft Basic
Display Adapter rather than a proper driver; confirmed via Windows Update
that no better driver was available in this isolated environment. Documented
as a genuine driver/hardware limitation rather than forcing a fix that
wasn't there, and restored the one setting that was fixable (scaling, back
to 125% recommended).

**Content search returned nothing for a file that definitely existed.**
Windows' search index hadn't caught up on the freshly built VM, so searching
for "budget" found nothing even after the file's content was confirmed
correct. Worked around it by sorting Documents by Date Modified (descending)
across subfolders instead, which surfaced the file immediately regardless of
indexing state.

**Printing a test page didn't switch the default printer as expected.**
Assumed "Let Windows manage my default printer" would auto-switch to
whichever printer was last used, but it didn't take effect through a test
print alone. Set the wrong printer as default manually instead to reproduce
the ticket, then fixed it the same way, and left auto-management switched
off afterwards to prevent the same issue recurring on its own.

## What I'd do differently next time
- Use the direct vendor installer URL from the start rather than clicking
  through search results, to avoid redirect/signup dead ends
- Sign into TeamViewer immediately rather than assuming the ID/password view
  is the full feature set
- Don't rely on Windows Search content indexing for anything on a freshly
  built VM; sort by date modified as the default first move instead
- Turn off "manage my default printer automatically" as a standard step when
  setting up a second printer, rather than discovering the side effect later

## Screenshots
(see /screenshots in this folder)

- TeamViewer session connected, remote control confirmed
- 7-Zip installed and pinned to taskbar (Store Ops)
- Advanced Display showing Microsoft Basic Display Adapter (Head Office IT)
- Documents sorted by Date Modified surfacing the renamed file (Finance)
- Printers & scanners showing HR-Floor2-Printer restored as Default (HR)

## Resume-ready bullet
Provided remote troubleshooting and support across a simulated retail
business using TeamViewer, resolving application installation, display
driver, file recovery, and default-printer configuration issues across four
departments, diagnosing genuine root causes (driver limitations, search
indexing gaps, automatic default-printer reassignment) rather than surface-
level fixes.
