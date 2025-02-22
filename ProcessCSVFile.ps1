function Process_CSVFile {
    param (
        [string]$File, 
        [string]$PayorName,
        [string]$TargetTable,
        [string]$ArchivePath,
        [string]$Delimiter,
        [string]$ServerName,
        [string]$Database,
        [PSCredential]$Credential,
        [string]$LogFile
    )

    try {
        Write-Log "Processing CSV/TXT File: $File for Payor: $PayorName with Delimiter: '$Delimiter'" -LogFile $LogFile
        $DataTable = New-Object System.Data.DataTable

        # Default to comma if Delimiter is not set
        if (-not $Delimiter -or $Delimiter -eq "") {
            $Delimiter = ","
        } elseif ($Delimiter -eq "\t") {
            $Delimiter = "`t"  # Convert to actual tab character
        } else {
            $Delimiter = [char]$Delimiter  # Convert to the specified delimiter
        }
        
        # Get Column Mapping
        $ColumnMapping = Get-ColumnMapping -PayorName $PayorName -TargetTable $TargetTable -ServerName $ServerName -Database $Database -Credential $Credential -LogFile $LogFile
        $MappingHash = @{ }
        foreach ($Row in $ColumnMapping) {
            $MappingHash[$Row.IncomingColumn] = $Row.TargetColumn
            $DataTable.Columns.Add($Row.TargetColumn) | Out-Null
        }
        
        # Read CSV Data
        $Data = Import-Csv -Path $File -Delimiter ([char]$Delimiter)
        foreach ($Row in $Data) {
            $DataRow = $DataTable.NewRow()
            foreach ($Column in $Row.PSObject.Properties.Name) {
                if ($MappingHash.ContainsKey($Column)) {
                    $DataRow[$MappingHash[$Column]] = $Row.$Column
                }
            }
            # Add the SourceFileName to the row
            $DataRow["SourceFileName"] = [System.IO.Path]::GetFileName($File)

            $DataTable.Rows.Add($DataRow)
        }
        
        # Perform Bulk Insert
        $connString = "Server=$ServerName;Database=$Database;User Id=$Username;Password=$Password;TrustServerCertificate=True;"
        $bulkCopy = New-Object Data.SqlClient.SqlBulkCopy($connString)
        $bulkCopy.DestinationTableName = $TargetTable

        # Add column mappings
        foreach ($Column in $DataTable.Columns) {
            $bulkCopy.ColumnMappings.Add($Column.ColumnName, $Column.ColumnName)
        }

        $bulkCopy.WriteToServer($DataTable)

        Write-Log "Bulk insert completed for $TargetTable" -LogFile $LogFile
        Move-Item -Path $File -Destination $ArchivePath -Force
        Write-Log "File moved to archive: $ArchivePath" -LogFile $LogFile
    } catch {
        Write-Log "Error processing CSV/TXT file: $_" -LogFile $LogFile
    }
}
