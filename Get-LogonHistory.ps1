<#
.Synopsis
    Extracts recent logon history for the local machine from the Security Event Log.
.Description
    This script scans through the Security Event Log on the local machine for interactive logons (both local and remote), and logouts.
    
    It then constructs a PowerShell Custom Object containing the fields of interest and writes that object to the pipeline as its output.
    
    NOTE: This script must be run 'As Administrator' in order to access the Security Event Log.
    
    To run this function on a remote computer, use it in conjunction with the Invoke-Command cmdlet.
.Inputs
    None. You cannot pipe input to this script.
.Outputs
    System.Management.Automation.PSCustomObject
    
    Get-LogonHistory returns a custom object containing the following properties:
    
    [String]UserName
        The username of the account that logged on/off of the machine.
    [String]ComputerName
        The name of the computer that the user logged on to/off of.
    [String]Action
        The action the user took with regards to the computer. Either 'logon' or 'logoff'.
    [String]LogonType
        Either 'console' or 'remote', depending on how the user logged on. This property is null if the user logged off.
    [DateTime]TimeStamp
        A DateTime object representing the date and time that the user logged on/off.
.Notes
    
.Example
    .\Get-LogonHistory.ps1
    
    Description
    -----------
    Gets the available logon entries in the Security log on the local computer.
.Example
    Invoke-Command -ComputerName 'remotecomputer' -File '.\Get-LogonHistory.ps1'
    
    Description
    -----------
    Gets the available logon entries in the Security log on a remote computer named 'remotecomputer'.
#>


function Get-Win7LogonHistory {
    $logons = Get-EventLog Security -AsBaseObject -InstanceId 4624,4647 |
              Where-Object { ($_.InstanceId -eq 4647) `
                        -or (($_.InstanceId -eq 4624) -and ($_.Message -match "Logon Type:\s+2")) `
                        -or (($_.InstanceId -eq 4624) -and ($_.Message -match "Logon Type:\s+10")) }
    $poweroffs = Get-EventLog System -AsBaseObject -InstanceId 41
    $events = $logons + $poweroffs | Sort-Object TimeGenerated
    
    if ($events) {
        foreach($event in $events) {
            # Parse logon data from the Event.
            if ($event.InstanceId -eq 4624) {
                # A user logged on.
                $action = 'logon'
                
                $event.Message -match "Logon Type:\s+(\d+)" | Out-Null
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
                if ($event.message -match "New Logon:\s*Security ID:\s*.*\s*Account Name:\s*(\w+)") {
                    $user = $matches[1]
                } else {
                    $index = $event.index
                    Write-Warning "Unable to parse Security log Event. Malformed entry? Index: $index"
                }
                
            } elseif ($event.InstanceId -eq 4647) {
                # A user logged off.
                $action = 'logoff'
                $logonType = $null
                
                # Determine user.
                if ($event.message -match "Subject:\s*Security ID:\s*.*\s*Account Name:\s*(\w+)") {
                    $user = $matches[1]
                } else {
                    $index = $event.index
                    Write-Warning "Unable to parse Security log Event. Malformed entry? Index: $index"
                }
            } elseif ($event.InstanceId -eq 41) {
                # The computer crashed.
                $action = 'logoff'
                $logonType = $null
                $user = '*'
            }
        
            # As long as we managed to parse the Event, print output.
            if ($user) {
                $timeStamp = Get-Date $event.TimeGenerated
                $output = New-Object -Type PSCustomObject
                Add-Member -MemberType NoteProperty -Name 'UserName' -Value $user -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $env:computername -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'Action' -Value $action -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'LogonType' -Value $logonType -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value $timeStamp -InputObject $output
                Write-Output $output
            }
        }
    } else {
        Write-Host "No recent logon/logoff events."
    }
}

function Get-WinXPLogonHistory {
    $logons = Get-EventLog Security -AsBaseObject -InstanceId 528,551 |
              Where-Object { ($_.InstanceId -eq 551) `
                        -or (($_.InstanceId -eq 528) -and ($_.Message -match "Logon Type:\s+2")) `
                        -or (($_.InstanceId -eq 528) -and ($_.Message -match "Logon Type:\s+10")) }
    #$poweroffs = Get-Eventlog System -AsBaseObject -InstanceId 6008
    #$events = $logons + $poweroffs | Sort-Object TimeGenerated
    
    if ($events) {
        foreach($event in $events) {
            # Parse logon data from the Event.
            if ($event.InstanceId -eq 528) {
                # A user logged on.
                $action = 'logon'
                
                $event.Message -match "Logon Type:\s+(\d+)" | Out-Null
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
                if ($event.message -match "Successful Logon:\s*User Name:\s*(\w+)") {
                    $user = $matches[1]
                } else {
                    $index = $event.index
                    Write-Warning "Unable to parse Security log Event. Malformed entry? Index: $index"
                }
                
            } elseif ($event.InstanceId -eq 551) {
                # A user logged off.
                $action = 'logoff'
                $logonType = $null
                
                # Determine user.
                if ($event.message -match "User initiated logoff:\s*User Name:\s*(\w+)") {
                    $user = $matches[1]
                } else {
                    $index = $event.index
                    Write-Warning "Unable to parse Security log Event. Malformed entry? Index: $index"
                }
            }# elseif ($event.InstanceId -eq 6008) {
                # The computer crashed.
            #    $action = 'logoff'
            #    $logonType = $null
            #    $user = '*'
            #}
        
            # As long as we managed to parse the Event, print output.
            if ($user) {
                $timeStamp = Get-Date $event.TimeGenerated
                $output = New-Object -Type PSCustomObject
                Add-Member -MemberType NoteProperty -Name 'UserName' -Value $user -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $env:computername -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'Action' -Value $action -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'LogonType' -Value $logonType -InputObject $output
                Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value $timeStamp -InputObject $output
                Write-Output $output
            }
        }
    } else {
        Write-Host "No recent logon/logoff events."
    }
}
$OSversion = (Get-WmiObject -Query 'SELECT version FROM Win32_OperatingSystem').version
if ($OSversion -ge 6) {
    Get-Win7LogonHistory
} else {
    Get-WinXPLogonHistory
}