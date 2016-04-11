function Add-ClipboardText
{
    <#
        .SYNOPSIS
            Sets Clipboard Text.
        .DESCRIPTION
            Sets Clipboard Text.
        .EXAMPLE
            PS> Add-ClipboardText -ClipText "Test Text"
            
            This Example will Set the clipboard to "Test Text"
        .EXAMPLE
            PS> Add-ClipboardText -ClipText "Text Text" -Append
            
            This Exmaple Will append the text "Test Text" to the current clipboard text.
        .PARAMETER ClipText
            Specify to set the Clipboard Text.
        .PARAMETER Append
            Specify to append $ClipText to Current Text in clipboard
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [String] $ClipText,
        [Parameter(Position=1,Mandatory=$false)]
        [ValidateNotNull()]
        [Switch] $Append
    )
    begin
    {
        try
        {
            Add-Type -Assembly PresentationCore -ErrorAction stop -ErrorVariable ErrorPresentationCore   
            if($Append)
            {
                $CurrentText = Get-ClipboardText
                if ($CurrentText -eq $null)
                {
                    [string]$CurrentText = ""
                }
            } 
        }
        catch
        {
            if($ErrorPresentationCore){ Write-Warning -Message "[BEGIN] An Error has Occured while importing the Assembly PresenationCore" }
            Write-Warning -Message "[BEGIN] $($_.Exception.Message)"
        }        
    }
    process
    {
        try
        {
            $CurrentText += $ClipText
            [Windows.Clipboard]::SetText($CurrentText)     
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An Error has occured while Setting the Clipboard Text"
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"    
        }
    }
}

function Get-ClipboardText
{
    <#
        .SYNOPSIS
            This Function Gets the Current Clipboard Text.
        .DESCRIPTION
            This Function Gets the Current Clipboard Text.
        .EXAMPLE
            PS>Get-ClipboardText
            
            This Exmaple gets the current clipboard text.
    #>
    [CmdletBinding()]
    param()
    begin
    {
        try
        {
            Add-Type -Assembly PresentationCore -ErrorAction stop -ErrorVariable ErrorPresentationCore    
        }
        catch
        {
            if($ErrorPresentationCore){ Write-Warning -Message "[BEGIN] An Error has Occured while importing the Assembly PresenationCore" }
            Write-Warning -Message "[BEGIN] $($_.Exception.Message)"
        }      
    }
    process
    {
        try
        {
            if([Windows.Clipboard]::ContainsText())
            {
                $ClipText=[Windows.Clipboard]::GetText()
            }
            else
            {
                Write-Verbose "[PROCESS] Clipboard Does not contain Text Data."    
            }
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An Error has occured while Getting the Clipboard Text"
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"    
        }
        finally
        {
            Write-Output $ClipText
        }
    }
}

function Add-ClipboardFile
{
    <#
        .SYNOPSIS
            Copies file(s) to clipboard.
        .DESCRIPTION
            Copies file(s) to clipboard.
        .EXAMPLE
            PS> Add-ClipboardFile -File "c:\my\path\to\file0.log","c:\my\path\to\file1.txt"
            
            This Example Copies to files to the clipboard (file0.log and file1.txt)
        .PARAMETER File
            Specify a file or a list of files to be copied to clipboard.
        .PARAMETER Append
            Specify to append file to files already in clipboard
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [object[]] $File,
        [Parameter(Position=1,Mandatory=$false)]
        [ValidateNotNull()]
        [switch] $Append
    )
    begin
    {
        try
        {
            Add-Type -Assembly PresentationCore -ErrorAction stop -ErrorVariable ErrorPresentationCore
            
            if ($Append)
            {
                [System.Collections.Specialized.StringCollection] $FileCollection = Get-ClipboardFile 
                if($FileCollection -eq $null)
                {
                    $FileCollection = New-Object System.Collections.Specialized.StringCollection  -ErrorAction stop -ErrorVariable ErrorStringCollection    
                }
            }
            else 
            {
                $FileCollection = New-Object System.Collections.Specialized.StringCollection  -ErrorAction stop -ErrorVariable ErrorStringCollection    
            }
        }
        catch
        {
            if($ErrorPresentationCore){ Write-Warning -Message "[BEGIN] An Error has Occured while importing the Assembly PresenationCore." }
            if($ErrorStringCollection){ Write-Warning -Message "[BEGIN] An Error has Occured while creating object StringCollection." }
            Write-Warning -Message "[BEGIN] $($_.Exception.Message)"
        }          
    }
    process
    {
        try
        {
            foreach($FileName in $File)
            {
                if($FileName.GetType() -eq [System.IO.FileInfo])
                {
                    $FileName = $FileName.FullName    
                }
                
                if(Test-Path -Path $FileName -ErrorVariable ErrorTestPath)
                {
                    $FileCollection.Add($FileName) | Out-Null
                    Write-Verbose "[PROCESS] Adding File: $($FileName) to clipboard."
                }
                else
                {
                    Write-Warning -Message "[PROCESS] A File Provided does not exist or is inaccessible: $FileName Skipping"
                }    
            }
            [Windows.Clipboard]::SetFileDropList($FileCollection)
        }
        catch
        {
            Write-Warning -Message '[PROCESS] An Error has occured.'
            if($ErrorTestPath){ Write-Warning -Message "[PROCESS] $ErrorTestPath" }
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"
        }
    }
}

function Get-ClipboardFile
{
    <#
        .SYNOPSIS
            This Function will get a list of files that are in the clipboard
        .DESCRIPTION
            This Function will get a list of files that are in the clipboard
        .EXAMPLE
            PS>Get-ClipboardFile
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.StringCollection])]
    param()
    begin
    {
        try
        {
            Add-Type -Assembly PresentationCore -ErrorAction stop -ErrorVariable ErrorPresentationCore
            $FileCollection = New-Object System.Collections.Specialized.StringCollection  -ErrorAction stop -ErrorVariable ErrorStringCollection
        }
        catch
        {
            if($ErrorPresentationCore){ Write-Warning -Message "[BEGIN] An Error has Occured while importing the Assembly PresenationCore." }
            if($ErrorStringCollection){ Write-Warning -Message "[BEGIN] An Error has Occured while creating object StringCollection." }
            Write-Warning -Message "[BEGIN] $($_.Exception.Message)"
        }          
    }
    process
    {
        try
        {
            if([Windows.Clipboard]::ContainsFileDropList())
            {
                $FileCollection = [Windows.Clipboard]::GetFileDropList()    
            }
            else
            {
                Write-Verbose -Message "[PROCESS] Unable to get current clipboard file list, as the clipboard does not contain StringCollection data."    
            }
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An Error has occured."
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"
        }
        finally
        {
            $FileCollection
        }
    }
}

function Remove-Clipboard 
{
    <#
        .SYNOPSIS
            Clears Clipboard of all data.
        .DESCRIPTION
            Clears Clipboard of all data.
        .EXAMPLE
            PS>Remove-Clipboard
            
            This Example clears the clipboard.
    #>
    [CmdletBinding()]
    param()
    begin 
    {
        try
        {
            Add-Type -Assembly PresentationCore -ErrorAction stop -ErrorVariable ErrorPresentationCore    
        }
        catch
        {
            if($ErrorPresentationCore){ Write-Warning -Message "[BEGIN] An Error has Occured while importing the Assembly PresenationCore" }
            Write-Warning -Message "[BEGIN] $($_.Exception.Message)"
        } 
    }
    process 
    {
        try
        {
            $ClipText=[Windows.Clipboard]::Clear()    
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An Error has occured while Clearing the Clipboard Text"
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"    
        }
    }
    
}
