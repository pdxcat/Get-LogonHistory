Get-LogonHistory
================

Gets recent logons/logouts from the Windows Security Log on the local
machine, and outputs them as custom PowerShell objects.

Usage: 
------
	.\Get-LogonHistory.ps1

Use Get-Help
------------ 
.\Get-LogonHistory.ps1 for more information.

Export-Logons-ToPgSQL
=====================

A PowerShell module containing a function that takes logon data and 
pipes it into a PostgreSQL database. It was necessary to make this a
function instead of a script so it could handle pipeline input.

Usage:
------
To use the function, first import the module into your PowerShell
session by using the Import-Module cmdlet, e.g.

Import-Module 
-------------
	'\\path\to\Export-Logons-ToPgSQL.psm1'

You can then call the function as if it were a cmdlet itself, e.g.

	Export-Logons-ToPgSQL -UserName 'bob' -ComputerName 'LAB1' -LogonType 'console' `
						  -Action 'logon' -TimeStamp [DateTime]'2013-02-10 10:50:00'

Requirements:
-------------
ODBC drivers must be installed (these can be obtained from PostgreSQL.org)
and an ODBC Data Source named Pgsql_logondb must be configured to connect to the
target database.

The script assumes the following database schema:

	TABLE logons(username VARCHAR(20), compname VARCHAR(20),\n
				 logontype VARCHAR(10), action VARCHAR(10), date DATE,\n
				 time TIME, PRIMARY KEY (username,compname,action,date,time))

Use Get-Help Export-Logons-ToPgSQL after importing the module for more
information.