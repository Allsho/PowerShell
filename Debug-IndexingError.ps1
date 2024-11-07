param (
    [string]$LogFilePath = "./debug_log.txt",
    [string]$ServerName,
    [string]$DatabaseName,
    [string]$Query
)

# Function to write debug messages to log
function Write-DebugLog {
    param ([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFilePath -Value "$timestamp - $Message"
}

# Step 1: Retrieve Data Mappings from Database
Write-DebugLog "Starting data mapping retrieval from database..."
try {
    $mappingConfig = Get-SqlData -ServerName $ServerName -DatabaseName $DatabaseName -Query $Query

    if ($null -eq $mappingConfig) {
        Write-Host "Error: Mapping configuration is null."
        Write-DebugLog "Mapping configuration is null."
        exit
    } elseif ($mappingConfig.Rows.Count -eq 0) {
        Write-Host "Warning: No data found in the mapping configuration."
        Write-DebugLog "No data found in the mapping configuration."
        exit
    } else {
        Write-Host "Mapping configuration retrieved. Row count: $($mappingConfig.Rows.Count)"
        Write-DebugLog "Mapping configuration retrieved. Row count: $($mappingConfig.Rows.Count)"
    }
} catch {
    Write-Host "Error: Failed to retrieve mapping configuration. $_"
    Write-DebugLog "Failed to retrieve mapping configuration. $_"
    exit
}

# Step 2: Validate Array Indexes
Write-DebugLog "Validating data mapping indices..."
try {
    $rowIndex = 0  
    $columnIndex = "ColumnName"

    if ($rowIndex -ge $mappingConfig.Rows.Count) {
        Write-Host "Error: Row index $rowIndex is out of bounds."
        Write-DebugLog "Row index $rowIndex is out of bounds. Mapping row count: $($mappingConfig.Rows.Count)"
    } elseif ($null -eq $mappingConfig.Rows[$rowIndex][$columnIndex]) {
        Write-Host "Error: Value at Row $rowIndex, Column '$columnIndex' is null."
        Write-DebugLog "Value at Row $rowIndex, Column '$columnIndex' is null."
    } else {
        Write-Host "Value at Row $rowIndex, Column '$columnIndex' is valid."
        Write-DebugLog "Value at Row $rowIndex, Column '$columnIndex' is valid: $($mappingConfig.Rows[$rowIndex][$columnIndex])"
    }
} catch {
    Write-Host "Error: Indexing operation failed. $_"
    Write-DebugLog "Indexing operation failed. $_"
}
Write-Host "Debugging complete. Check $LogFilePath for details."
