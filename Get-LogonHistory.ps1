# Get-Logins
# Fetch console login data from the local machine.
$events = Get-EventLog Security -AsBaseObject -InstanceId 4624,4647
$logons = $events | Where-Object { ($_.InstanceId -eq 4647) `
                              -or (($_.InstanceId -eq 4624) -and ($_.Message -match "Logon Type:\s+2")) `
                              -or (($_.InstanceId -eq 4624) -and ($_.Message -match "Logon Type:\s+10")) }

foreach($logon in $logons) {
	# Parse logon data from the Event.
	if ($logon.InstanceId -eq 4624) {
		$action = 'logon'
		
		$logon.Message -match "Logon Type:\s+(\d+)" | Out-Null
		$logonTypeNum = $matches[1]
		
		# Determine logon type.
		if ($logonTypeNum -eq 2) {
			$logonType = 'console'
		} elseif ($logonTypeNum -eq 10) {
			$logonType = 'remote'
		} else {
			$logonType = 'other'
		}
		
		# Determine user.
		if ($logon.message -match "New Logon:\s*Security ID:\s*.*\s*Account Name:\s*(\w+)") {
			$user = $matches[1]
		} else {
			Write-Error "Unable to parse Security log. Malformed entry? Index: $logon.Index"
		}
		
	} else {
		$action = 'logoff'
		
		$logonType = $null
		
		# Determine user.
		if ($logon.message -match "Subject:\s*Security ID:\s*.*\s*Account Name:\s*(\w+)") {
			$user = $matches[1]
		} else {
			Write-Error "Unable to parse Security log. Malformed entry? Index: $logon.Index"
		}
	}
	$index = $logon.index
	
	# As long as we managed to parse the Event, print output.
	if ($user) {
		$time = Get-Date $logon.TimeGenerated
		$output = New-Object -Type PSCustomObject
		Add-Member -MemberType NoteProperty -Name 'UserName' -Value $user -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'Action' -Value $action -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'LogonType' -Value $logonType -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'Time' -Value $time -InputObject $output
		Add-Member -MemberType NoteProperty -Name 'Index' -Value $index -InputObject $output
		Write-Output $output
	}
}