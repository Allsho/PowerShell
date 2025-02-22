function Process_ExcelFile {
    param (
        [string]$File,
        [string]$PayorName,
        [string]$TargetTable,
        [string]$SheetName,
        [string]$ArchivePath,
        [string]$ServerName,
        [string]$Database,
        [PSCredential]$Credential,
        [string]$LogFile
    )

    try {
        Write-Log "Processing Excel File: $File (Sheet: $SheetName) for Payor: $PayorName" -LogFile $LogFile

        # Extract just the filename
        $SourceFileName = [System.IO.Path]::GetFileName($File)

        # Get Column Mapping
        $ColumnMapping = Get-ColumnMapping -PayorName $PayorName -TargetTable $TargetTable -ServerName $ServerName -Database $Database -Credential $Credential -LogFile $LogFile
        $MappingHash = @{ }
        foreach ($Row in $ColumnMapping) {
            $MappingHash[$Row.IncomingColumn.ToLower().Trim()] = $Row.TargetColumn.Trim()
        }

        # Read Data from Excel Sheet
        $Data = Import-Excel -Path $File -WorksheetName $SheetName
        $DataTable = New-Object System.Data.DataTable

        # Add columns to DataTable in the correct order
        foreach ($Row in $ColumnMapping) {
            $DataTable.Columns.Add($Row.TargetColumn) | Out-Null
        }

        # Check if SourceFileName column already exists before adding it
        if (-not $DataTable.Columns.Contains("SourceFileName")) {
            $DataTable.Columns.Add("SourceFileName") | Out-Null
        }

        # Populate DataTable
        foreach ($Row in $Data) {
            $DataRow = $DataTable.NewRow()
            foreach ($Column in $Row.PSObject.Properties.Name) {
                if ($MappingHash.ContainsKey($Column.ToLower().Trim())) {
                    $DataRow[$MappingHash[$Column.ToLower().Trim()]] = $Row.$Column
                }
            }
            # Add the SourceFileName to the row
            $DataRow["SourceFileName"] = $SourceFileName
            $DataTable.Rows.Add($DataRow)
        }

        # Perform Bulk Insert with explicit column mapping
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
        Write-Log "Error processing Excel file: $_" -LogFile $LogFile
    }
}
