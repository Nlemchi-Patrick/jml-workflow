param(
    [switch]$DryRun
)

# =================================================
# JML MASTER ORCHESTRATOR
# Runs full lifecycle in order
# =================================================

# Always load common first
. "$PSScriptRoot\common.ps1" -DryRun:$DryRun


Write-Host ""
Write-Host "[STEP 1] Backup current users and groups"
& "$PSScriptRoot\backup.ps1" -DryRun:$DryRun


Write-Host ""
Write-Host "[STEP 2] Process Joiners"
& "$PSScriptRoot\joiners.ps1" -DryRun:$DryRun


Write-Host ""
Write-Host "[STEP 3] Process Movers"
& "$PSScriptRoot\movers.ps1" -DryRun:$DryRun


Write-Host ""
Write-Host "[STEP 4] Process Leavers"
& "$PSScriptRoot\leavers.ps1" -DryRun:$DryRun


Write-Host ""
Write-Host "[STEP 5] Check logs"
Write-Host "[ALL STEPS COMPLETE]"