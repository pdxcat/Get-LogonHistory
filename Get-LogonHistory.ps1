# Get-Logins
# Fetch login data from the local machine.

$events = Get-EventLog Security -AsBaseObject -InstanceId 4624,4647
$logons = $events | Where-Object { ($_.InstanceId -eq 4647) -or (($_.InstanceId -eq 4624) -and ($_.Message -match "Logon Type:\s+2")) }

$logons