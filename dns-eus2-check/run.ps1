# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$AppName = "sapp-p-cus-sql-2-sql.database.windows.net."
$DnsServers = @(
    #"10.204.0.9",
    "10.204.0.5"
)

$Output = @()
foreach ($Server in $DnsServers) {
    $Props = @{
        DateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Server = $Server
        AppName = $AppName
        LookupResult = ""
        ServiceState = ""
    }
    $DnsResult = (nslookup $AppName $server 2>$null | sls address | ? {$_.linenumber -eq 5}).ToString().Split(":")[1].Trim()
    if ($DnsResult.Count -gt 0) {
        $Props.ServiceState = "UP"
        $Props.LookupResult = $DnsResult
    }
    else {
        $Props.LookupResult = "FAILED"
        $ConnTest = Test-NetConnection -ComputerName $Server -Port 53
        if ($ConnTest.TcpTestSucceeded) {
            $Props.ServiceState = "UP"
        } else {
            $Props.ServiceState = "UNREACHABLE"
        }
    }
    $Output += New-Object PSObject -Property $Props
}

$Output | Format-Table -AutoSize

# foreach ($Entry in $Output) {
#     if ($Entry.LookupResult -eq "FAILED") {
#         Write-Error -Message "DNS lookup failed for $AppName on server $Server, service state: $Entry.ServiceState"
#     }
# }

# # Write an information log with the current time.
# Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

# $sb = {
#     param($AppName, $Server)
#     $Props = @{
#         DateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
#         Server = $Server
#         AppName = $AppName
#         LookupResult = ""
#         ServiceState = ""
#         TimeTaken = ""
#     }
    
#     $TimeTaken = Measure-Command {$DnsResult = (nslookup $AppName $server 2>$null | sls address | select -last 1).ToString().Split(":")[1].Trim()}
#     $Props.TimeTaken = $TimeTaken.TotalMilliseconds

#     if ($DnsResult.Count -gt 0) {
#         $Props.LookupResult = $DnsResult
#         $Props.ServiceState = "UP"
#     } else {
#         $Props.LookupResult = "FAILED"
#         $ConnTest = Test-NetConnection -ComputerName $Server -Port 53
#         if ($ConnTest.TcpTestSucceeded) {
#             $Props.ServiceState = "UP"
#         } else {
#             $Props.ServiceState = "UNREACHABLE"
#         }
#     }
#     $Obj = New-Object PSObject -Property $Props

#     $Obj
# }

# $ResultOutput = @()
# foreach ($Server in $DnsServers) {
#     Start-Job -ScriptBlock $sb -ArgumentList $AppName, $Server | Out-Null
#     do {
#         $Result = Get-Job | Receive-Job -Wait -AutoRemoveJob
#         $ResultOutput += $Result
#     } while ($Result -eq $null)
# }

# Write-Output $ResultOutput | Format-Table -AutoSize