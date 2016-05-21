function Get-TrackPackageStatus
{
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $TrackingNumber,
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateSet("UPS","USPS")]
        [String] $Carrier
    )
    process
    {
        #Build Carrier URI
        switch($Carrier)
        {
            "UPS" {$TrackingURI = "https://wwwapps.ups.com/WebTracking/track?track=yes&trackNums=$($TrackingNumber)"}
            "USPS" {$TrackingURI = "https://tools.usps.com/go/TrackConfirmAction?tLabels=$($TrackingNumber)"}
        }        
        #GetSite Content and Parse
        $Site = Invoke-WebRequest -Uri $TrackingURI
        if($Carrier -eq "USPS")
        {
            $HTMLTable = ($Site.AllElements | Where-Object { $_.Class -eq "zebra-table" } | Select-Object -exp innerHtml)
            if($HTMLTable -eq $null)
            {
                Write-Warning -Message "Could Not Find Tracking Number."
                exit
            }
            [Array] $ColumnHeaders = @()
            [Array] $RowValues = @()
            $str="`n"
            $chr= [Convert]::ToChar($str)
            foreach($line in $HTMLTable.Split($chr))
            {
                if($line -match '<TR')
                {
                    $IsBeginRow = $true
                }
                elseif($IsBeginRow -eq $true -and $line -match "</DIV></TH>") 
                {
                    $ColumnHeaders += ([Regex]::Match($line,'(?<=>).*?(?=</DIV>)').Groups[0].Value -replace "&nbsp;"," " -replace "&amp;" -replace " +"," ")  
                    if ($line -match ".+</TR>")
                    {
                        $IsBeginRow = $false
                    }
                }
                elseif($IsBeginRow -eq $true -and $line -match "<P" -and $line -notmatch "^<P id=LabelSummaryDetails")
                {
                    $RowValues += ([Regex]::Match($line,'(?<=>)[^<>]+(?=<)').Groups[0].Value -replace "&nbsp;"," " -replace " +"," ")
                    if ($line -match ".+</TR>")
                    {
                        if ($RowValues.Length -gt $ColumnHeaders.Length)
                        {
                            $diff = $RowValues.Length - $ColumnHeaders.Length
                            if($diff -eq 1)
                            {
                                $RowValues[$RowValues.Length -2] = "$($RowValues[$RowValues.Length -2])$($RowValues[$RowValues.Length -1])"
                            }
                            # $Counter = 0
                            # $EmptyIndex = @()
                            # foreach($cell in $RowValues)
                            # {
                            #     if ($cell -eq "")
                            #     {
                            #         $EmptyIndex += $counter
                            #     }
                            #     $counter++
                            # }
                            # if ($EmptyIndex.Length -le $diff)
                            # {
                            #     $TempRowValues = @()
                            #     foreach($cell in $RowValues)
                            #     {
                            #         if ($cell -eq "")
                            #     }
                            # }
                        }
                        $IsBeginRow = $false
                        $row = New-Object -TypeName PSObject
                        for($i = 0; $i -lt $ColumnHeaders.Length; $i++)
                        {
                            $row | Add-Member -MemberType NoteProperty -Name $ColumnHeaders[$i] -Value $RowValues[$i]    
                        }
                        $RowValues = @()
                        $row   
                    }
                }
            }
        }
        elseif($Carrier -eq "UPS")
        {
            $HTMLTable = ($site.AllElements | Where-Object { $_.Class -eq "dataTable" } | Select-Object -exp innerHTML)
            if($HTMLTable -eq $null)
            {
                Write-Warning -Message "Could Not Find Tracking Number."
                exit
            }
            [Array] $ColumnHeaders = @()
            [Array] $RowValues = @()
            $str="`n"
            $chr= [Convert]::ToChar($str)
            foreach($line in $HTMLTable.Split($chr))
            {
                if($line -match '<TR')
                {
                        $IsBeginRow = $true
                }
                elseif($IsBeginRow -eq $true -and $line -match "<TH") 
                {
                    $ColumnHeaders += [Regex]::Match($line,'(?<=>).*?(?=</TH>)').Groups[0].Value  
                    if ($line -match ".+</TR>")
                    {
                        $IsBeginRow = $false
                    }
                }
                elseif($IsBeginRow -eq $true -and $line -match "<TD")
                {
                    $RowValues += [Regex]::Match($line,'(?<=>).*?(?=</TD>)').Groups[0].Value
                    if ($line -match ".+</TR>")
                    {
                        $IsBeginRow = $false
                        $row = New-Object -TypeName PSObject
                        for($i = 0; $i -lt $ColumnHeaders.Length; $i++)
                        {
                            $row | Add-Member -MemberType NoteProperty -Name $ColumnHeaders[$i] -Value $RowValues[$i]    
                        }
                        $RowValues = @()
                        $row   
                    }
                }
            }
        }
    }
}




