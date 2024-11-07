function Get-SqlData {
    param (
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$Query
    )

    $connectionString = "Server=$ServerName;Database=$DatabaseName;Integrated Security=True;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query

        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $dataTable = New-Object System.Data.DataTable
        $adapter.Fill($dataTable)
        return $dataTable
    } catch {
        throw "Error retrieving data: $($_.Exception.Message)"
    } finally {
        $connection.Close()
    }
}
