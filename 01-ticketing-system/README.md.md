# Project 1: Ticketing System — Northgate Retail Group Helpdesk

## What this is

A working helpdesk built with osTicket, configured as if I'm the sole IT support tech for Northgate Retail Group, a small retail business with a Head Office and two store locations. Set up on a local LAMP stack (XAMPP: Apache, MySQL, PHP), from a completely clean install.

## What I built

- **Ticketing system**: osTicket v1.18.4 installed on XAMPP (Apache/MySQL/PHP)
- **4 help topics** matching Northgate's structure: Head Office IT, Store Ops, Finance, Human Resource
- **2 SLA plans**: Standard (48hr response, applied to Head Office IT/Finance/HR) and Priority (4hr response, applied to Store Ops — store-level issues like till or network faults need faster turnaround than head office admin requests)
- **5 sample tickets** raised as different Northgate users and fully triaged: resolved with a documented note in each case, covering Outlook sync, till printer, store Wi-Fi, login lockout, and VPN connectivity

## Tools

osTicket, XAMPP (Apache, MySQL, PHP), Windows, WSL2/Ubuntu (for repo management)

## What broke, and how I fixed it

This is the part that actually mirrors real Tier 1 work — nothing about the install "just worked."

**Windows Mark-of-the-Web blocking a config file.** osTicket's installer needs `include/ost-config.php` to exist (renamed from a sample file) before it'll proceed. I renamed it correctly, but the installer kept reporting the file as missing. Turned out Windows had flagged the file, extracted from a downloaded zip, with a security block ("this file came from another computer"). Unblocking it via the file's Properties dialog resolved it. This is a genuinely useful thing to know if you're setting up any local dev tooling on Windows from downloaded archives.

**VirtualBox/WSL2 conflict** (relevant context, not unique to this project but hit early in the rebuild): Hyper-V (which WSL2 depends on) and VirtualBox compete for the same virtualisation extensions. Running `bcdedit /set hypervisorlaunchtype auto` let both coexist rather than fighting over the CPU.

**Database connection failures during install** — three separate causes, diagnosed one at a time via Apache's error log (`C:\xampp\apache\logs\error.log`) rather than guesswork:
1. A mismatched MySQL root password from a stale value the browser had auto-filled into what looked like a blank field.
2. A one-character typo (`roo` instead of `root`) in the MySQL username field on a resubmission.
3. The `osticket` database not existing yet — the installer expected it, but I had to create it manually with `CREATE DATABASE IF NOT EXISTS osticket;` before the install would complete.

Each of these produced the same generic-looking 500 error in the browser. The actual cause only became clear from reading the PHP fatal error text in Apache's log file directly, which is the same diagnostic instinct you'd use troubleshooting a live support ticket: don't guess from the symptom, check the log.

**XAMPP doesn't survive a reboot.** After restarting the laptop, both Apache and MySQL needed manually restarting via the XAMPP Control Panel; they're not registered as background Windows services by default.

## What I'd do differently next time

- Set the MySQL root password deliberately before starting the install, rather than relying on the "blank password" default, to avoid the ambiguity that caused two of the three database connection failures.
- Create the target database manually before running the installer, rather than assuming osTicket's installer creates it automatically.
- Keep browser autofill switched off during any credential-entry-heavy setup like this, it caused more confusion than it saved.

## Screenshots

*(see /screenshots in this folder)*
- Help Topics list showing all four Northgate categories
- SLA plans (Standard, Priority)
- Resolved ticket queue showing all 5 sample tickets

## Resume-ready bullet

> Deployed and configured osTicket as a simulated company helpdesk (Northgate Retail Group), handling ticket triage, escalation, and resolution across four departments with tiered SLAs, diagnosing and resolving genuine installation issues (Windows file-blocking behaviour, database configuration errors) using Apache/PHP error logs.
