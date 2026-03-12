param(
    [switch]$DryRun,
    [string]$BackupFile
)
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun
Connect-GraphApp

Write-Log "Processing ROLLBACK"

# Auto-select latest backup if none specified
if (-not $BackupFile) {
    $latest = Get-ChildItem $BackupFolder | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-Log "No backup files found in $BackupFolder" "ERROR"
        exit
    }
    $BackupFile = $latest.FullName
    Write-Log "No backup specified. Using latest: $BackupFile"
}

if (-not (Test-Path $BackupFile)) {
    Write-Log "Backup file not found: $BackupFile" "ERROR"
    exit
}

$data = Get-Content $BackupFile | ConvertFrom-Json
Write-Log "Rollback using $BackupFile"

foreach ($u in $data) {
    Invoke-Safely "Restore $($u.UserPrincipalName)" {
        $user = Get-MgUser -UserId $u.UserPrincipalName
        if (-not $user) {
            Write-Log "User not found: $($u.UserPrincipalName)" "WARN"
            return
        }

        # Restore account enabled state
        Update-MgUser -UserId $u.UserPrincipalName -AccountEnabled:$u.Enabled

        # Remove current group memberships
        Get-MgUserMemberOf -UserId $user.Id | ForEach-Object {
            Remove-MgGroupMemberByRef -GroupId $_.Id -DirectoryObjectId $user.Id
        }

        # Re-add to backed up groups
        foreach ($gid in $u.Groups) {
            New-MgGroupMemberByRef -GroupId $gid -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
            }
        }

        Write-Log "Restored $($u.UserPrincipalName)"
    }
}

Write-Log "Rollback complete"