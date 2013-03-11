<#
.Synopsis
	Takes logon and logoff data and inserts it into a PostgreSQL database.
.Description
	This function uses the PostgreSQL ODBC driver and a pre-configured PostgreSQL Data Source to establish a connection to a PostgreSQL database.
	
	It then takes input from arguments on the command line or from the pipeline and attempts to insert them into a database containing logon/logoff data.
	
	The function expects/assumes the following database schema:

	TABLE logons(username VARCHAR(20), compname VARCHAR(20),
	             logontype VARCHAR(10), action VARCHAR(10), date DATE,
	             time TIME, PRIMARY KEY (username,compname,action,date,time))
.Inputs
	This function takes the following inputs. These can also be passed in by property name via the pipeline:
	
	[String]UserName
		The username of the account that logged on/off of the machine.
	[String]ComputerName
		The name of the computer that the user logged on to/off of.
	[String]Action
		The action the user took with regards to the computer. Either 'logon' or 'logoff'.
	[String]LogonType
		Either 'console' or 'remote', depending on how the user logged on. This property is ignored if the value of action is 'logoff'.
	[DateTime]TimeStamp
		A DateTime object representing the date and time that the user logged on/off.
.Outputs
	Export-Logons-ToPgSQL writes a summary of changes to the console window, indicating how many new rows were inserted, how many rows were already in the database (and therefore rejected), and how many inserts failed due to some other error.
	
.Example
	.\Get-LogonHistory.ps1 | Export-Logons-ToPgSQL
	
	Description
	-----------
	Gets the available logon entries in the Security log on the local computer, then imports them into the PostgreSQL database.
.Example
	Invoke-Command -ComputerName 'remotecomputer' -File '.\Get-LogonHistory.ps1' | Export-Logons-ToPgSQL
	
	Description
	-----------
	Gets the available logon entries in the Security log on a remote computer named 'remotecomputer', then imports them into the PostgreSQL database.

.Example
	Export-Logons-ToPgSQL -UserName 'bob' -ComputerName 'LAB1' -LogonType 'console' -Action 'logon' -TimeStamp [DateTime]'2013-02-10 10:50:00'
	
	Description
	-----------
	Inserts a manually crafted logon entry into the PostgreSQL database.
#>
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
		[DateTime]$TimeStamp,
		[Parameter(Mandatory=$false,
		           ValueFromPipelineByPropertyName=$false)]
		[String]$LogFile = ''
	)
	
	BEGIN {
		# Check that log file path is valid, if given.
		if ($LogFile -eq '') {
			$logToFile = $false
		} else {
			try {
				$pathToLogFile = Split-Path -Parent -Path $LogFile
			} catch {
				Write-Error $_
				break
			}
			if (Test-Path $pathToLogFile) {
				$logToFile = $true
			} else {
				Write-Error "Invalid path to log file specified."
				break
			}
		}
		
		# If logging, begin writing to logfile.
		if ($logToFile) {
			$date = Get-Date
			"[$date]" | Out-File -FilePath $LogFile -Encoding ASCII -Append -NoClobber
		}
		
		# Create and prep DB connection objects and establish connection.
		$DBConn = New-Object System.Data.Odbc.OdbcConnection('DSN=Pgsql_logondb')
		$DBCmd = $DBConn.CreateCommand()
		$DBCmd.CommandText = 'INSERT INTO logons (username,compname,logontype,action,date,time)'
		$DBCmd.CommandText += ' VALUES (?,?,?,?,?,?);'
		[void]$DBCmd.Parameters.Add('@username', [System.Data.Odbc.OdbcType]::varchar, 20)
		[void]$DBCmd.Parameters.Add('@compname', [System.Data.Odbc.OdbcType]::varchar, 20)
		[void]$DBCmd.Parameters.Add('@logontype', [System.Data.Odbc.OdbcType]::varchar, 10)
		[void]$DBCmd.Parameters.Add('@action', [System.Data.Odbc.OdbcType]::varchar, 10)
		[void]$DBCmd.Parameters.Add('@date', [System.Data.Odbc.OdbcType]::date)
		[void]$DBCmd.Parameters.Add('@time', [System.Data.Odbc.OdbcType]::time)
		$newRows = $oldRows = $errRows = 0
		try {
			$DBCmd.Connection.Open()
		} catch {
			if ($logToFile) {
				$_ | Out-File -FilePath $LogFile -Encoding ASCII -Append -NoClobber
			} else {
				Write-Error $_
			}
			break
		}
	}
	
	PROCESS {
		# Parse data and attempt to insert a row into the database.
		[DateTime]$date = $TimeStamp.date
		[TimeSpan]$time = Get-Date $TimeStamp -Format 'HH:mm:ss'
		$DBCmd.Parameters['@username'].Value = $UserName
		$DBCmd.Parameters['@compname'].Value = $ComputerName
		$DBCmd.Parameters['@logontype'].Value = $LogonType
		$DBCmd.Parameters['@action'].Value = $Action
		$DBCmd.Parameters['@date'].Value = $date
		$DBCmd.Parameters['@time'].Value = $time
		try {
			[void]$DBCmd.ExecuteNonQuery()
			$newRows = $newRows + 1
		} catch {
			$uniqueErr = '*ERROR `[23505`] ERROR: duplicate key value violates unique constraint*'
			if ($_.exception -like $uniqueErr) {
				$oldRows = $oldRows + 1
			} else {
				if ($logToFile) {
					$_ | Out-File -FilePath $LogFile -Encoding ASCII -Append -NoClobber
				} else {
					Write-Error $_
				}
				$errRows = $errRows + 1
			}
		}
	}
	
	END {
		$DBCmd.Connection.Close()
		if ($logToFile) {
			"$newRows new rows written to database." | Out-File -FilePath $LogFile -Encoding ASCII -Append -NoClobber
			"$oldRows existing rows discarded." | Out-File -FilePath $LogFile -Encoding ASCII -Append -NoClobber
			"$errRows rows failed to insert for unknown reasons." | Out-File -FilePath $LogFile -Encoding ASCII -Append -NoClobber
		} else {
			if ($newRows) { Write-Host "$newRows new rows written to database." }
			if ($oldRows) { Write-Host "$oldRows existing rows discarded." }
			if ($errRows) { Write-Host "$errRows rows failed to insert for unknown reasons." }
		}
	}
}