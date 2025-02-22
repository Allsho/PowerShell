# PowerShell Script for ETL Process Using Claim_Data_Mapping and Table_Mapping

param (
    [string]$ServerName = "",
    [string]$Database = "ClaimsStage",
    [string]$Username = "sa",
    [string]$Password = "",
    [string]$LogFile = "E:\PowerShell\Logs\ETL_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Import the ImportExcel module
Import-Module ImportExcel

# Import custom modules
. "E:/PowerShell/Logging.ps1"
. "E:/PowerShell/DatabaseFunctions.ps1"
. "E:/PowerShell/ProcessCSVFile.ps1"
. "E:/PowerShell/ProcessExcelFile.ps1"

# Convert Password to Secure String
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

# Main Process
$Payors = @("NEMGCigna_Member", "NEMGAnthem_Member")

foreach ($Payor in $Payors) {
    try {
        $Mapping = Get-TableMapping -PayorName $Payor -ServerName $ServerName -Database $Database -Credential $credential -LogFile $LogFile

        Write-Log "Scanning for $($Mapping.FileType) files in $($Mapping.SourcePath) for Payor: $Payor" -LogFile $LogFile
        $Files = Get-ChildItem -Path $Mapping.SourcePath -Filter $Mapping.FilePattern
        
        foreach ($File in $Files) {
            if ($Mapping.FileType -in "csv", "txt") {
                Process_CSVFile -File $File.FullName -PayorName $Payor -TargetTable $Mapping.TargetTable -ArchivePath $Mapping.ArchivePath -Delimiter $Mapping.Delimiter -ServerName $ServerName -Database $Database -Credential $credential -LogFile $LogFile
            } elseif ($Mapping.FileType -in "xlsx", "xls") {
                Process_ExcelFile -File $File.FullName -PayorName $Payor -TargetTable $Mapping.TargetTable -SheetName $Mapping.SheetName -ArchivePath $Mapping.ArchivePath -ServerName $ServerName -Database $Database -Credential $credential -LogFile $LogFile
            }
        }
    } catch {
        Write-Log "Error processing files for Payor: $Payor - $_" -LogFile $LogFile
    }
}

Write-Log "ETL Process Completed!" -LogFile $LogFile
