param(
    [switch]$DryRun
)
# -------------------------------------------------
# Bootstrap (ALWAYS first)
# -------------------------------------------------
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun
Connect-GraphApp

# -------------------------------------------------
# Paths (root-anchored, never relative)
# -------------------------------------------------
$root      = Split-Path $PSScriptRoot -Parent
$CsvPath   = Join-Path $root "data\hr-feed.csv"
$BackupDir = Join-Path $root "logs\backups"

# Ensure folders exist
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = Join-Path $BackupDir "backup-$timestamp.json"

# -------------------------------------------------
# Validation
# -------------------------------------------------
if (!(Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

# -------------------------------------------------
# Backup process
# -------------------------------------------------
Write-Log "Starting backup"

$csv  = Import-Csv $CsvPath
$data = @()

foreach ($u in $csv) {
    try {
        Write-Log "Processing $($u.UserPrincipalName)"

        $user = Get-MgUser -UserId $u.UserPrincipalName -ErrorAction Stop

        $groups = Get-MgUserMemberOf -UserId $user.Id -All |
                  Select-Object -ExpandProperty Id

        $data += [PSCustomObject]@{
            UserPrincipalName = $u.UserPrincipalName
            Enabled           = $user.AccountEnabled
            Groups            = $groups
        }
    }
    catch {
        Write-Log "Failed: $($u.UserPrincipalName) -> $($_.Exception.Message)" "WARN"
    }
}

# -------------------------------------------------
# Output
# -------------------------------------------------
if ($DryRun) {
    Write-Log "DryRun enabled — no file written"
}
else {
    $data | ConvertTo-Json -Depth 5 | Out-File $BackupFile -Encoding utf8
    Write-Log "Backup saved -> $BackupFile"
}

Write-Log "Backup complete"