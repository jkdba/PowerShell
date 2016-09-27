function Watch-Server 
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ComputerName,

        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [ValidateNotNullorEmpty()]
        #5 hours
        [Int] $TimeOutSeconds = $(5*60*60)

        # [Parameter(
        #   Position = 2,
        #   Mandatory = $false
        # )]
        # [ValidateNotNullorEmpty()]
        # [Int] $IntervalSeconds = 1
    )
    process
    {
        #Build Job Name to be unique
        $JobName = $ComputerName
        $JobNameCount = (get-job | Where-Object Name -like $JobName*).Count
        $JobName = "$($JobName)_$($JobNameCount)"

        #Define and Start job
        # $Job = Start-Job -Name $JobName -ScriptBlock { 
        #     param($ComputerName, $TimeOut)

            $CheckState = $null
            $Count = 1

            while ($true)
            {
                if ($Count -gt $TimeOutSeconds)
                {
                    ##Notify Exceeded TimeOut
                    New-ToastNotification -AppName "PNG" -Title "$ComputerName" -Body "$ComputerName Cancelled due to timeout. Ping Count: $Count."
                    break;
                }
                ##Test Connection
                $null = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue -ErrorVariable ErrorPing
                ###Interpret Results
                if(-not $ErrorPing)
                {
                    $ConnectionState = $true
                }
                elseif($ErrorPing.Exception.InnerException -eq 'No such host is known')
                {
                    # $ConnectionState = $false
                    ##Notify Host Does Not exist
                    New-ToastNotification -AppName "PNG" -Title "$ComputerName" -Body "$ComputerName Does Not Exist. Ping Count: $Count."
                    break;
                }
                else
                {
                    $ConnectionState = $false
                }

                ##Check if State has changed
                ###If first check set initial check state.
                if(-not $CheckState)
                {
                    $CheckState = $ConnectionState
                }
                elseif($ConnectionState -ne $CheckState)
                {
                    if($ConnectionState)
                    {
                        ##Notify Server up
                        New-ToastNotification -AppName "PNG" -Title "$ComputerName Up" -Body "$ComputerName is Up. Ping Count: $Count." 
                        break;
                    }
                    else
                    {
                        ##Notify StateChange
                        if($ConnectionState)
                        {
                            $StateDescription = 'Up'
                        }
                        else
                        {
                            $StateDescription = 'Down'
                        }
                        New-ToastNotification -AppName "PNG" -Title "$ComputerName $StateDescription" -Body "$ComputerName State has Changed: $StateDescription. Ping Count: $Count"
                    }

                    ##Update CheckState
                    $CheckState = $ConnectionState
                }

                # if($ConnectionState)
                # {
                #     Start-Sleep -seconds 1
                # }
                ##Always Count.
                $Count++;
            }
        # } -ArgumentList $ComputerName,$TimeOutSeconds

        # #Create Event to clean up job after complete
        # $null = Register-ObjectEvent -InputObject $Job -EventName "StateChanged" -Action { 
            
        #     #Logic to handle state change
        #     if($sender.State -match "Complete"){
        #       Remove-Job $sender.Id
        #     }
        #     else{
        #       Write-Warning -Message "Job $($sender.Name) completed with an unexpected status: $($sender.State)."
        #     }
            
        #     #Unregister event and remove event job 
        #     Unregister-Event -SubscriptionId $Event.EventIdentifier
        #     Remove-Job -Name $event.SourceIdentifier
        # }
    }
}

Watch-Server -ComputerName 'jklann10-v1'