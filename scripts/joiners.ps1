param(
    [switch]$DryRun
)
# -------------------------------------------------
# Load shared config, logging, auth, paths
# -------------------------------------------------
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun
Connect-GraphApp
Write-Log "Processing JOINERS"

# --------------------------
# Department → Group mapping
# --------------------------
$GroupMap = @{
    "Sales"   = "Test-Sales-Users"
    "Finance" = "Test-Finance-Users"
    "HR"      = "Test-HR-Users"
}

$rows = Import-Csv $CsvPath | Where-Object { $_.Action -eq "Join" }

foreach ($u in $rows) {
    $groupName = $GroupMap[$u.Department]
    if (-not $groupName) {
        Write-Log "No group mapping for department: $($u.Department)" "WARN"
        continue
    }

    Invoke-Safely "Create user $($u.UserPrincipalName)" {

        # Check if user already exists
        $user = Get-MgUser -UserId $u.UserPrincipalName -ErrorAction SilentlyContinue

        if ($user) {
            Write-Log "User already exists, skipping creation: $($u.UserPrincipalName)" "WARN"
        }
        else {
            # Create user
            $user = New-MgUser `
                -DisplayName $u.DisplayName `
                -UserPrincipalName $u.UserPrincipalName `
                -Department $u.Department `
                -AccountEnabled:$true `
                -MailNickname ($u.DisplayName -replace " ","") `
                -PasswordProfile @{
                    Password = "TempP@ss123!"
                    ForceChangePasswordNextSignIn = $true
                }
            Write-Log "User created: $($u.UserPrincipalName)"
        }

        # Add to department group
        $group = Get-MgGroup -Filter "displayName eq '$groupName'"
        if ($group) {
            # Check if already a member
            $isMember = Get-MgGroupMember -GroupId $group.Id | Where-Object { $_.Id -eq $user.Id }
            if ($isMember) {
                Write-Log "Already a member of $groupName, skipping: $($u.UserPrincipalName)" "WARN"
            }
            else {
                New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
                }
                Write-Log "Added $($u.UserPrincipalName) → $groupName"
            }
        }
        else {
            Write-Log "Group not found: $groupName" "ERROR"
        }
    }
}

Write-Log "Joiners processing complete"