function Watch-Server
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "Server"
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "IPV4"
        )]
        [ValidateNotNullOrEmpty()]
        [String] $IPV4,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            ParameterSetName = "IPV4"
        )]
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ParameterSetName = "Server"
        )]
        [ValidateSet("StateChange","Reboot","Up","Down")]
        [String] $MonitorType,

        [Parameter(
            Position = 2,
            Mandatory = $false,
            ParameterSetName = "IPV4"
        )]
        [Parameter(
            Position = 2,
            Mandatory = $false,
            ParameterSetName = "Server"
        )]
        [Int] $TimeOut = 300
    )
    process
    {

        if ($PsCmdlet.ParameterSetName -eq 'Server')
        {
            $IsRealHost = nslookup $ComputerName
            if ($IsRealHost -match "can't find")
            {
                Write-Warning -Message "Unable to Find Host: $ComputerName"
                break;
            }
        }
        else
        {
            $ComputerName = $IPV4    
        }

        $null = Start-Job -Name "Png $ComputerName" -ScriptBlock {
            param($ComputerName, $TimeOut)
            $AppName = "ServerMonitor"
            
            $counter = 0
            $CheckResult = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue -ErrorVariable $TestErrorVariable
            while($true)
            {
                $result = ping "$ComputerName" -n 1 -4 -l 32
                if($result -match "bytes=32")
                {
                    New-ToastNotification -AppName $AppName -Title "[UP]: $ComputerName" -Body "$ComputerName is Up. Ping Count: $counter" 
                    if($MonitorType -eq "StateChange")
                    {

                    }
                    break;
                }
                elseif($result -match "Ping request could not find host")
                {
                    New-ToastNotification -AppName $AppName -Title "[FAIL]: $ComputerName" -Body "Unable to Lookup: $ComputerName. Ping Count: $counter"
                    break;
                }
                else
                {
                    if($counter -ge $TimeOut)
                    {
                        New-ToastNotification -AppName $AppName -Title "[TIMEOUT]: $ComputerName" -Body "$ComputerName Has been unpingable for the max TimeOut: $TimeOut. Ping Count: $counter"
                        break;
                    }
                    $counter++
                    Start-Sleep 1
                }
            }
        } -argumentlist $ComputerName, $TimeOut
    }
}