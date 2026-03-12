

🛠 Joiner–Mover–Leaver (JML) HR Automation Workflow
Automate user lifecycle management in Microsoft Entra ID (Azure AD) using PowerShell and Microsoft Graph.  
This project covers Join → Move → Leave operations with logging, backups, rollback, and full orchestration.
---
Table of Contents
Overview
Features
Department → Group Mapping
Folder Structure
Scripts
CSV HR Feed
Logging & Backup
Setup Instructions
Running the Workflow
Screenshots
Authors
---
Overview
This workflow automates common enterprise IAM tasks:
Onboard new employees (Joiners)
Move employees across departments (Movers)
Offboard employees who leave (Leavers)
It uses:
CSV HR feed (`data/hr-feed.csv`)
PowerShell scripts
Microsoft Graph API via App Registration (SDK v2)
Logging, backup, and rollback
Orchestrator for full end-to-end automation
> ✅ Enterprise-ready, auditable, and schedulable workflow.
---
Features
Automated user creation and group assignment
Department updates and group reallocation
User disabling and group removal
Backup and rollback for safety
Detailed logging (`logs/jml-log.txt`)
Non-interactive authentication using App Registration
Dry-run mode for safe testing
Master orchestrator to run all steps sequentially
---
Department → Group Mapping
Department	Group Name
Sales	Test-Sales-Users
Finance	Test-Finance-Users
HR	Test-HR-Users
> Modify `$DepartmentGroupMap` in `common.ps1` if additional departments are added.
---
Folder Structure
```text
jml-workflow/
│
├─ scripts/          # Joiners, Movers, Leavers, backup, rollback, orchestrator
├─ data/             # HR CSV feed
├─ logs/             # Generated logs and backups
│   └─ backups/      # JSON backups for rollback
├─ screenshots/      # Demo screenshots
└─ README.md         # Project documentation
```
---
Scripts
Script	Purpose
`joiners.ps1`	Create new users and assign mapped groups
`update-department.ps1`	Update departments and group memberships
`leavers.ps1`	Disable users and remove from groups
`backup.ps1`	Snapshot current users and groups for rollback
`rollback.ps1`	Restore users/groups from backup
`common.ps1`	Shared functions (logging, Graph auth, helpers)
`jml-master.ps1`	Orchestrator script running full workflow
---
CSV HR Feed
The HR feed (`data/hr-feed.csv`) drives all operations. The `Action` column determines which script processes each row:
Action	Processed By	What Happens
`Join`	`joiners.ps1`	User created and added to group
`Move`	`update-department.ps1`	Department and group updated
`Leave`	`leavers.ps1`	Account disabled, removed from groups
Example CSV:
```csv
Action,UserPrincipalName,DisplayName,Department
Join,john.doe@yourdomain.onmicrosoft.com,John Doe,Sales
Join,david.kim@yourdomain.onmicrosoft.com,David Kim,Finance
Join,peter.obi@yourdomain.onmicrosoft.com,Peter Obi,HR
Move,john.doe@yourdomain.onmicrosoft.com,John Doe,Finance
Leave,david.kim@yourdomain.onmicrosoft.com,David Kim,Finance
```
> ⚠️ The column must be named `UserPrincipalName` — not `UPN`.
---
Logging & Backup
Logs: `logs/jml-log.txt` — structured timestamped entries for each Join/Move/Leave action
Backups: `logs/backups/backup-YYYYMMDD-HHmmss.json` — captures users' accounts, groups, and department for rollback
Example log entry:
```
2026-03-11 09:01:12 [INFO] User created: john.doe@yourdomain.onmicrosoft.com
2026-03-11 09:01:13 [INFO] Added john.doe@yourdomain.onmicrosoft.com → Test-Sales-Users
```
---
Setup Instructions
1. Create required groups in Entra ID:
`Test-Sales-Users`
`Test-Finance-Users`
`Test-HR-Users`
2. Register an App in Entra ID with these application permissions:
`User.ReadWrite.All`
`Group.ReadWrite.All`
`Directory.ReadWrite.All`
`AuditLog.Read.All`
3. Update `common.ps1` with your credentials:
```powershell
$TenantId     = "your-tenant-id"
$ClientId     = "your-client-id"
$ClientSecret = "your-client-secret"
```
4. Install Microsoft Graph PowerShell SDK v2:
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
```
> ⚠️ This project runs on **SDK v2**. The cmdlet `Add-MgGroupMemberByRef` was removed in v2 — `New-MgGroupMemberByRef` is used throughout.
5. Prepare the HR feed CSV at `data/hr-feed.csv` (see CSV section above).
---
Running the Workflow
Dry Run (test, no changes made):
```powershell
.\scripts\jml-master.ps1 -DryRun
```
Production Run:
```powershell
.\scripts\jml-master.ps1
```
Run individual scripts:
```powershell
.\scripts\joiners.ps1
.\scripts\update-department.ps1
.\scripts\leavers.ps1
```
Rollback:
```powershell
.\scripts\rollback.ps1 -BackupFile logs\backups\backup-YYYYMMDD-HHmmss.json
```
Verify users were created:
```powershell
Get-MgUser -ConsistencyLevel eventual -Filter "endsWith(UserPrincipalName,'@yourdomain.onmicrosoft.com')" | Select-Object DisplayName, UserPrincipalName, Department, AccountEnabled | Format-Table
```
---
Screenshots
Step	Screenshot
Groups created	01-groups-created.png
App Registration permissions	02-app-registration-permissions.png
HR CSV feed	03-hr-csv.png
Backup created	04-backup-created.png
Users created	05-users-created.png
Groups updated	06-groups-updated.png
Joiners script successful  07-joiners.png
Movers script successful  08-move-(department change).png
Leavers script successful  09-user-account-disabled.png
Log file	10-log-file.png
Rollback success	11-rollback-success.png
Orchestrator run	12-orchestrator-run.png
Task Scheduler	13-task-scheduler.png
> Place screenshots in `/screenshots` for full documentation.
---
Authors
Nlemchi Patrick  
GitHub / LinkedIn / Email (optional)
> Maintainer: This repository demonstrates enterprise-level IAM automation using PowerShell and Microsoft Graph.
---
Notes
The workflow uses `Test-*` groups for demonstration purposes
`$DepartmentGroupMap` in `common.ps1` controls group assignment centrally across all scripts
Always run in dry-run mode first before executing in production
Logs and backups provide full auditability and rollback capability
The CSV column header must be `UserPrincipalName` (not `UPN`)