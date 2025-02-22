function Write-Log {
    param ([string]$Message, [string]$LogFile)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}
