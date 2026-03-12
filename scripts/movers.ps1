param([switch]$DryRun)
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun
Connect-GraphApp

$GroupMap = @{
    "Sales"   = "Test-Sales-Users"
    "Finance" = "Test-Finance-Users"
    "HR"      = "Test-HR-Users"
}

$rows = Import-Csv $CsvPath | Where-Object { $_.Action -eq "Move" }

if (-not $rows) {
    Write-Log "No movers found in HR feed"
}

foreach ($u in $rows) {
    $newGroupName = $GroupMap[$u.Department]
    if (-not $newGroupName) {
        Write-Log "No group mapping for department: $($u.Department)" "WARN"
        continue
    }
    Invoke-Safely "Move user $($u.UserPrincipalName)" {
        $user = Get-MgUser -UserId $u.UserPrincipalName
        if (-not $user) {
            Write-Log "User not found: $($u.UserPrincipalName)" "WARN"
            return
        }
        # Remove from all current groups
        Get-MgUserMemberOf -UserId $user.Id | ForEach-Object {
            Remove-MgGroupMemberByRef -GroupId $_.Id -DirectoryObjectId $user.Id
        }
        # Update department
        Update-MgUser -UserId $u.UserPrincipalName -Department $u.Department
        # Add to new group
        $group = Get-MgGroup -Filter "displayName eq '$newGroupName'"
        if ($group) {
            New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
            }
            Write-Log "Moved $($u.UserPrincipalName) → $newGroupName"
        } else {
            Write-Log "Group not found: $newGroupName" "ERROR"
        }
    }
}

Write-Log "Movers processing complete"