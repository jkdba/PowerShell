
function Invoke-StructureCopy
{
    <#
        .SYNOPSIS
            This Function will Replicate Folder and File structures.
        .DESCRIPTION
            This Function will Replicate Folder and File structures. It can be used on both local and remote(cifs)
            target and source locations.
            
            This Function will Replicate some of the File Metadata such as the Modification Dates, and Creation Dates.
            Currently this functionality is limited to Files only and not directories.
            
            All other metadata is not yet copied suchs as permissions.
            
            Note that this function does not "Copy" the files and folders it creates "Replicas" of them. So file sizes
            will all be 0 bytes.
            
            The primary purpose of this function is either to generate test data or to copy a directory structure.
        .EXAMPLE
            PS> Invoke-StructureCopy -SourceDirectory 'c:\path\to\source' -TargetDirectory 'c:\path\to\target'
            
            This Example will replicate the folder and file structure of the source to the target.
        .EXAMPLE
            PS> Invoke-StructureCopy -SourceDirectory 'c:\path\to\source' -TargetDirectory 'c:\path\to\target' -DirectoryOnly
            
            This Example will replicate only the folder structure of the source to the target.
        .PARAMETER SourceDirectory
            Specify the SourceDirectory to Start Replicating From.
        .PARAMETER TargetDirectory
            Specify the TargetDirectory to Replicate To.
        .PARAMETER
            Specify to only Replicate the Directory Structure.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String] $SourceDirectory,
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String] $TargetDirectory,
        [Parameter(Position=2, Mandatory=$false)]
        [Switch] $DirectoryOnly
    )
    begin{}
    process
    {
        try
        {
            $StructureList = Get-ChildItem -Path $SourceDirectory -Recurse
            
            foreach ($item in $StructureList)
            {
                $NewItemPath = $item.FullName.Replace($SourceDirectory, $TargetDirectory)
                if(Test-Path $NewItemPath)
                {
                    Write-Verbose -Message "Item Already Exists at: $NewItemPath Skipping"
                }
                else
                {
                    if($item.PSIsContainer)
                    {
                        Write-Debug -Message "Old Path: `n`t $($item.FullPath) `nNewPath: `n`t $NewItemPath"
                        Write-Verbose -Message "Creating new directory: $NewItemPath"
                        New-Item -type Directory -Path $NewItemPath -ErrorAction Stop -ErrorVariable ErrorNewDirectory > $null
                    }
                    elseif(-not $DirectoryOnly)
                    {
                        Write-Verbose -Message "Creating new file: $NewItemPath"
                        $FileMeta = Get-FileMetaData -File $item
                        $NewFile = New-Item -ItemType File -Path $NewItemPath -Value "Test Data" -ErrorAction Stop -ErrorVariable ErrorNewFile
                        Set-FileMetaData -File $NewFile -FileMetaData $FileMeta
                    }
                }
            }
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An error has occured."
            if($ErrorNewDirectory){ Write-Warning -Message "[PROCESS] An error occured while creating a new directory" }
            if($ErrorNewFile){ Write-Warning -Message "[PROCESS] An error occured while creating a new file" }
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"
        }
    }
}

function Get-FileMetaData
{
    <#
        .SYNOPSIS 
            This function gets Metadata from a specified File.
        .DESCRIPTION
            This function gets Metadata from a specified File. 
            Currently only gets properties from FileInfo Class that support setting.
        .EXAMPLE
            PS> Get-FileMetaData -File $FileInfoObject
            
            This Example will get the File Metadata from the System.IO.FileInfo object.
        .PARAMETER File
            Specify file info object to get metadata from.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo] $File
    )
    begin{}
    process
    {
        try
        {
            $MetaObject = @{
                'CreateDate' = $File.CreationTime
                'ModifyDate' = $File.LastWriteTime
                'AccessDate' = $File.LastAccessTime
                'IsReadOnly' = $File.IsReadOnly
            }
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An error occured while getting file metadata: $File"
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"
        }
        finally
        {
            $MetaObject
        }
    }
}

function Set-FileMetaData
{
    <#
        .SYNOPSIS
            This Function Sets the Metadata on a specified object.
        .DESCRIPTION
            This Function Sets the Metadata on a specified object.
            Currently only gets properties from FileInfo Class that support setting.
        .EXAMPLE
            PS> Set-FileMetaData -File $FileInfoObject -FileMetaData $FileMetaDataObject
            
            This Example Sets the File Metadata on the spcified System.IO.FileInfo Object using 
            the FileMetadata Object generated by Get-FileMetaData function.
        .PARAMETER File
            Specify file info object to set metadata on.
        .PARAMETER FileMetadata
            Specify file metadata object to get metadata to be set.
            
            Set function Get-FileMetaData.
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo] $File,
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject] $FileMetadata
    )
    begin{}
    process
    {
        try
        {
            $File.CreationTime = $FileMetadata.CreateDate
            $File.LastWriteTime = $FileMetadata.ModifyDate
            $File.LastAccessTime = $FileMetadata.AccessDate
            $File.IsReadOnly = $FileMetadata.IsReadOnly
        }
        catch
        {
            Write-Warning -Message "[PROCESS] An error occured while setting the File Metadata: $File"
            Write-Warning -Message "[PROCESS] $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function 'Invoke-StructureCopy'