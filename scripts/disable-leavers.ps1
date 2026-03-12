param(
    [switch]$DryRun
)

# =========================================================
# Load common utilities (paths, logging, Graph connection)
# =========================================================
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun

Connect-GraphApp

Write-Log "Processing LEAVERS (disable accounts)"

# =========================================================
# Load HR feed
# =========================================================
$rows = Get-HRFeed | Where-Object { $_.Action -eq "Leave" }

if (-not $rows) {
    Write-Log "No leavers found in HR feed"
    return
}

foreach ($u in $rows) {

    # Adjust column name if needed
    $upn = $u.UserPrincipalName

    if ([string]::IsNullOrWhiteSpace($upn)) {
        Write-Log "Missing UPN for leaver row — skipping" "WARN"
        continue
    }

    Write-Log "Processing leaver: $upn"

    # Reliable lookup (no filter)
    $user = Get-MgUser -UserId $upn -ErrorAction SilentlyContinue

    if (!$user) {
        Write-Log "User not found: $upn — skipping" "WARN"
        continue
    }

    # =====================================================
    # Disable account (DryRun-aware)
    # =====================================================
    Invoke-IfNotDryRun `
        -Description "Disable account for $upn" `
        -Action {
            Update-MgUser `
                -UserId $user.Id `
                -AccountEnabled:$false
        }
}

Write-Log "Leavers processing complete"