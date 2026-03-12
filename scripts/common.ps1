param(
    [switch]$DryRun
)

# =========================================================
# JML Common Utilities
# Shared across: joiners / movers / leavers / backup / master
# Single source of truth for paths, auth, logging, helpers
# =========================================================


# =========================================================
# PATHS (always relative to /scripts)
# =========================================================

$ProjectRoot  = Split-Path $PSScriptRoot -Parent

$DataFolder   = Join-Path $ProjectRoot "data"
$LogsFolder   = Join-Path $ProjectRoot "logs"
$BackupFolder = Join-Path $LogsFolder  "backups"

$CsvPath      = Join-Path $DataFolder "hr-feed.csv"
$LogFile      = Join-Path $LogsFolder "jml-log.txt"

# Ensure folders exist
New-Item -ItemType Directory -Force -Path $LogsFolder   | Out-Null
New-Item -ItemType Directory -Force -Path $BackupFolder | Out-Null


# =========================================================
# APP REGISTRATION (Graph App-Only Auth)
# Replace with your real values
# =========================================================

$TenantId     = "your-tenant-id"
$ClientId     = "your-client-id"
$ClientSecret = "your-client-secret"


# =========================================================
# DEPARTMENT → GROUP MAP
# (uses your existing Test-* groups)
# =========================================================

$DepartmentGroupMap = @{
    "HR"      = "Test-HR-Users"
    "Finance" = "Test-Finance-Users"
    "Sales"   = "Test-Sales-Users"
}


# =========================================================
# LOGGING
# =========================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$Level] $Message"

    Add-Content -Path $LogFile -Value $entry
    Write-Host  $entry
}


# =========================================================
# GRAPH CONNECTION (App Registration)
# =========================================================

function Connect-GraphApp {

    Write-Log "Connecting to Microsoft Graph (App Registration)"

    try {

        $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        $credential   = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)

        Connect-MgGraph `
            -TenantId $TenantId `
            -ClientSecretCredential $credential `
            -NoWelcome `
            -ErrorAction Stop

        Write-Log "Graph connection successful"
    }
    catch {
        Write-Log "Graph connection FAILED: $($_.Exception.Message)" "ERROR"
        throw
    }
}


# =========================================================
# HR FEED LOADER
# =========================================================

function Get-HRFeed {

    if (!(Test-Path $CsvPath)) {
        Write-Log "HR feed not found at $CsvPath" "ERROR"
        throw "Missing HR feed"
    }

    Write-Log "Loading HR feed"

    return Import-Csv $CsvPath
}


# =========================================================
# BACKUP FILE GENERATOR
# =========================================================

function New-BackupFile {

    $file = Join-Path $BackupFolder ("backup-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")

    Write-Log "Backup file -> $file"

    return $file
}


# =========================================================
# GROUP HELPER
# =========================================================

function Get-GroupIdByName {
    param([string]$GroupName)

    $group = Get-MgGroup -Filter "displayName eq '$GroupName'"

    if (!$group) {
        Write-Log "Group not found: $GroupName" "ERROR"
        throw
    }

    return $group.Id
}


# =========================================================
# SAFE EXECUTION (supports DryRun)
# =========================================================

function Invoke-Safely {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-Log "[DRYRUN] $Description"
    }
    else {
        & $Action
        Write-Log $Description
    }
}


# =========================================================
# HEADER
# =========================================================

Write-Log "----------------------------------------"
Write-Log "JML Script Started  | DryRun=$DryRun"
Write-Log "----------------------------------------"
