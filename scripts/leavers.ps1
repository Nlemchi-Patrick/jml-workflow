param([switch]$DryRun)
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun
Connect-GraphApp

Write-Log "Processing LEAVERS"

$rows = Get-HRFeed | Where-Object { $_.Action -eq "Leave" }

if (-not $rows) {
    Write-Log "No leavers found in HR feed"
    exit
}

foreach ($u in $rows) {
    Write-Log "Processing $($u.DisplayName)"

    Invoke-Safely "Disabled $($u.UserPrincipalName)" {
        $user = Get-MgUser -UserId $u.UserPrincipalName
        if (-not $user) {
            Write-Log "User not found: $($u.UserPrincipalName)" "WARN"
            return
        }
        # Disable account
        Update-MgUser -UserId $u.UserPrincipalName -AccountEnabled:$false
        Write-Log "Account disabled: $($u.UserPrincipalName)"

        # Remove from all groups
        Get-MgUserMemberOf -UserId $user.Id | ForEach-Object {
            Remove-MgGroupMemberByRef -GroupId $_.Id -DirectoryObjectId $user.Id
        }
        Write-Log "Removed from all groups: $($u.UserPrincipalName)"

        # Optionally add to Disabled-Users group
        $disabled = Get-MgGroup -Filter "displayName eq 'Disabled-Users'"
        if ($disabled) {
            New-MgGroupMemberByRef -GroupId $disabled.Id -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
            }
            Write-Log "Added to Disabled-Users group: $($u.UserPrincipalName)"
        }
    }
}

Write-Log "Leavers processing complete"