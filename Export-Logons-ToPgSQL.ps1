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
	BEGIN{
		$DBConn = New-Object System.Data.Odbc.OdbcConnection('DSN=Pgsql_logondb')
		$DBCmd = $DBConn.CreateCommand()
		$DBCmd.CommandText = 'INSERT INTO logins (username,compname,logontype,action,date,time) VALUES (?,?,?,?,?,?);'
		[void]$DBCmd.Parameters.Add('@username', [System.Data.Odbc.OdbcType]::varchar, 20)
		[void]$DBCmd.Parameters.Add('@compname', [System.Data.Odbc.OdbcType]::varchar, 20)
		[void]$DBCmd.Parameters.Add('@logontype', [System.Data.Odbc.OdbcType]::varchar, 10)
		[void]$DBCmd.Parameters.Add('@action', [System.Data.Odbc.OdbcType]::varchar, 10)
		[void]$DBCmd.Parameters.Add('@date', [System.Data.Odbc.OdbcType]::date)
		[void]$DBCmd.Parameters.Add('@time', [System.Data.Odbc.OdbcType]::time)
		$DBCmd.Connection.Open()
	}
	
	PROCESS{
		[DateTime]$date = $TimeStamp.date
		[TimeSpan]$time = Get-Date $TimeStamp -Format 'HH:mm:ss'
		$DBCmd.Parameters['@username'].Value = $UserName
		$DBCmd.Parameters['@compname'].Value = $ComputerName
		$DBCmd.Parameters['@logontype'].Value = $LogonType
		$DBCmd.Parameters['@action'].Value = $Action
		$DBCmd.Parameters['@date'].Value = $date
		$DBCmd.Parameters['@time'].Value = $time
		[void]$DBCmd.ExecuteNonQuery()
	}
	
	END{
		$DBCmd.Connection.Close()
	}
}