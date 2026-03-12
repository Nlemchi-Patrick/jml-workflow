if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory $LogFolder }

function Write-Log {
    param($Message)

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File "$LogFolder\jml-log.txt" -Append
    Write-Host "$time - $Message"
}

function Send-Alert {
    param($Subject,$Body)
    Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body
}

function Connect-GraphApp {
    Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -ClientSecret $ClientSecret -Scopes "User.ReadWrite.All","Group.ReadWrite.All"
}