# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$AppName = "sapp-p-cus-sql-2-sql.database.windows.net."
$DnsServers = @(
    "10.202.0.4",
    "10.202.0.5",
    "10.204.0.4",
    "10.204.0.5"
)

$ResultOutput = @()
foreach ($Server in $DnsServers) {
    $Props = @{
        Server = $Server
        AppName = $AppName
        LookupResult = ""
        ServiceState = ""
    }
    $DnsResult = Resolve-DnsName -Name $AppName -Server $Server
    if ($DnsResult.QueryResults.Count -gt 0) {
        $Props.LookupResult = $DnsResult.QueryResults.IPAddress
        $Props.ServiceState = "UP"
    } else {
        $Props.LookupResult = "FAILED"
        $ConnTest = Test-NetConnection -ComputerName $Server -Port 53
        if ($ConnTest.TcpTestSucceeded) {
            $Props.ServiceState = "UP"
        } else {
            $Props.ServiceState = "UNREACHABLE"
        }
    }
    $ResultOutput += New-Object PSObject -Property $Props
}

$ResultOutput | Format-Table -AutoSize