function Get-TableMapping {
    param ([string]$PayorName, [string]$ServerName, [string]$Database, [PSCredential]$Credential, [string]$LogFile)

    $Query = @"
    SELECT TargetTable, FilePattern, SheetName, FileType, SourcePath, ArchivePath, Delimiter
    FROM ClaimsStage.dbo.Table_Mapping
    WHERE PayorName = '$PayorName';
"@
    Write-Log "Fetching table mapping for Payor: $PayorName" -LogFile $LogFile
    return Invoke-SqlCmd -ServerInstance $ServerName -Database $Database -Query $Query -Credential $Credential -TrustServerCertificate
}

function Get-ColumnMapping {
    param ([string]$PayorName, [string]$TargetTable, [string]$ServerName, [string]$Database, [PSCredential]$Credential, [string]$LogFile)

    $Query = @"
    SELECT cdm.IncomingColumnName AS IncomingColumn, cdm.StandardizedColumnName AS TargetColumn
    FROM ClaimsStage.dbo.Claim_Data_Mapping cdm
    JOIN ClaimsStage.dbo.Table_Mapping tm ON cdm.PayorName = tm.PayorName AND cdm.IncomingColumnName IS NOT NULL
    WHERE cdm.PayorName = '$PayorName' AND tm.TargetTable = '$TargetTable';
"@
    Write-Log "Fetching column mapping for Payor: $PayorName, TargetTable: $TargetTable" -LogFile $LogFile
    return Invoke-SqlCmd -ServerInstance $ServerName -Database $Database -Query $Query -Credential $Credential -TrustServerCertificate
}
