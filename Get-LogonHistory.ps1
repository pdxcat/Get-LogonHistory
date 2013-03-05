# Get-Logins
# Fetch login data from the local machine.

$events = Get-EventLog Security -AsBaseObject -InstanceId 4624,4647
$logons = $events | Where-Object { ($_.InstanceId -eq 4647) -or (($_.InstanceId -eq 4624) -and ($_.Message -match "Logon Type:\s+2")) }

foreach($logon in $logons) {
	if ($logon.InstanceId -eq 4624) {
		$logonType = 'on'
		$logon.message -match "New Logon:\s*Security ID:\s*.*\s*Account Name:\s*(\w+)" | Out-Null
		$user = $matches[1]
	} else {
		$logonType = 'off'
		$logon.message -match "Subject:\s*Security ID:\s*.*\s*Account Name:\s*(\w+)" | Out-Null
		$user = $matches[1]
	}
	$time = Get-Date $logon.TimeGenerated
	Write-Host "$user,$logonType,$time"
}