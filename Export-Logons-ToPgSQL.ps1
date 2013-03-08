# Export login data into PostgreSQL DB.
# Requires that an appropriately named PgSQL ODBC Data Source be created first.

function Export-Logons-ToPgSQL {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true,
		           ValueFromPipelineByPropertyName=$True)]
		[String]$UserName,
		[Parameter(Mandatory=$true,
		           ValueFromPipelineByPropertyName=$True)]
		[String]$ComputerName,
		[Parameter(Mandatory=$true,
		           ValueFromPipelineByPropertyName=$True)]
		[String]$Action,
		[Parameter(Mandatory=$false,
		           ValueFromPipelineByPropertyName=$True)]
		[String]$LogonType,
		[Parameter(Mandatory=$true,
		           ValueFromPipelineByPropertyName=$True)]
		[DateTime]$TimeStamp
	)
	
	BEGIN {
		$DBConn = New-Object System.Data.Odbc.OdbcConnection('DSN=Pgsql_logondb')
		$DBCmd = $DBConn.CreateCommand()
		$DBCmd.CommandText = 'INSERT INTO logons (username,compname,logontype,action,date,time) VALUES (?,?,?,?,?,?);'
		[void]$DBCmd.Parameters.Add('@username', [System.Data.Odbc.OdbcType]::varchar, 20)
		[void]$DBCmd.Parameters.Add('@compname', [System.Data.Odbc.OdbcType]::varchar, 20)
		[void]$DBCmd.Parameters.Add('@logontype', [System.Data.Odbc.OdbcType]::varchar, 10)
		[void]$DBCmd.Parameters.Add('@action', [System.Data.Odbc.OdbcType]::varchar, 10)
		[void]$DBCmd.Parameters.Add('@date', [System.Data.Odbc.OdbcType]::date)
		[void]$DBCmd.Parameters.Add('@time', [System.Data.Odbc.OdbcType]::time)
		$DBCmd.Connection.Open() # Note: Do error checking here (for failure to connect, and authentication).
	}
	
	PROCESS {
		[DateTime]$date = $TimeStamp.date
		[TimeSpan]$time = Get-Date $TimeStamp -Format 'HH:mm:ss'
		$newRows = $oldRows = $errRows = 0
		$DBCmd.Parameters['@username'].Value = $UserName
		$DBCmd.Parameters['@compname'].Value = $ComputerName
		$DBCmd.Parameters['@logontype'].Value = $LogonType
		$DBCmd.Parameters['@action'].Value = $Action
		$DBCmd.Parameters['@date'].Value = $date
		$DBCmd.Parameters['@time'].Value = $time
		try {
			[void]$DBCmd.ExecuteNonQuery()
			$newRows = $newRows + 1
		} catch [System.Management.Automation.MethodInvocationException] {
			$uniqueErr = '*ERROR `[23505`] ERROR: duplicate key value violates unique constraint*'
			if ($_.exception -like $uniqueErr) {
				$oldRows = $oldRows + 1
			} else {
				Write-Error $_.exception
				$errRows = $errRows + 1
			}
		}
	}
	
	END {
		$DBCmd.Connection.Close()
		if ($newRows) { Write-Host "$newRows new rows written to database." }
		if ($oldRows) { Write-Host "$oldRows existing rows discarded." }
		if ($errRows) { Write-Host "$errRows rows failed to insert for unknown reasons." }
	}
}