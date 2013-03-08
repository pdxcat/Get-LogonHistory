Get-LogonHistory
================

Gets recent logons/logouts from the Windows Security Log on the local
machine, and outputs them as custom PowerShell objects.

Usage: Get-LogonHistory


Export-Logons-ToPgSQL
=====================

Takes logon data and pipes it into a PostgreSQL database. Requires that
ODBC drivers to be installed (these can be obtained from PostgreSQL.org)
and that an ODBC Data Source be configured to connect to the target
database.

The script assumes the following schema:

TABLE logons(username VARCHAR(20), compname VARCHAR(20),
             logontype VARCHAR(10), action VARCHAR(10), date DATE,
             time TIME, PRIMARY KEY (username,compname,action,date,time))
			 
Usage: Export-Logons-ToPgSQL -UserName [username] -ComputerName [compname]
                             -LogonType [logontype] -Action [action]
                             -TimeStamp [datetime]