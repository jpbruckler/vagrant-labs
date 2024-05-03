function Write-Log {
    <#
    .SYNOPSIS
        Write a log message to a log file.

    .DESCRIPTION
        This function writes a log message with a timestamp to a log file.
        The log level must be one of the following: INF, WRN, ERR, DBG, VRB.

    .PARAMETER Message
        The log message to write to the file.

    .PARAMETER Level
        The level of the log message. Must be one of the following: INF, WRN, ERR, DBG, VRB.

    .PARAMETER Path
        The path to the log file. Defaults to "log.txt" in the current directory.

    .EXAMPLE
        Write-Log -Message "This is a debug message" -Level DBG

        Writes a debug message to the log.txt file.

    .EXAMPLE
        Write-Log -Message "This is an error message" -Level ERR -LogFile "C:\Logs\mylog.txt"

        Writes an error message to the specified log file.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string] $Message,

        [Parameter(Mandatory=$true)]
        [ValidateSet("INF","WRN","ERR","DBG","VRB")]
        [string] $Level,

        [string] $Path = "log.txt",

        [int] $Indent = 0,

        [switch] $ToConsole
    )

    if ($Indent -gt 0) {
        $Tab = ' ' * (4 * $Indent)
    }
    else {
        $Tab = ''
    }
    try {
        Resolve-Path $Path -ErrorAction Stop | Out-Null
    }
    catch {
        New-Item -Path $Path -ItemType File -Force | Out-Null
    }

    # Current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff K"

    # Compose the log message using formatted string
    $MessageData = "{0} [{1}] {2}{3}" -f $timestamp, $Level, $Tab, $Message

    if ($ToConsole) {
        Write-Information -MessageData $MessageData -Tags 'IdentityManagement' -InformationAction Continue
    }

    # Write the log message to the log file
    Write-Information -MessageData $MessageData -Tags 'IdentityManagement' 6>> $Path
}

<#
    .SYNOPSIS
        Retrieves a list of currently used drive letters on the local machine.

    .DESCRIPTION
        This function queries the system to gather all currently used drive
        letters including both local and network drives. It returns a list of
        these letters, excluding the colon (:) for easier processing in scripts
        that require this information.

    .OUTPUTS
        System.Array
        Returns an array of strings, each representing a used drive letter.

    .EXAMPLE
        PS> Get-UsedDriveLetters
        Returns all the drive letters currently in use on the system, such as
        'C', 'D', and 'Z'.

    .NOTES
        This function utilizes CIM (Common Information Model) instances to
        access drive information, ensuring compatibility across different
        versions of Windows.
#>
function Get-UsedDriveLetters {
    # Get all current drive letters in use
    $usedDriveLetters = @()

    # Add local drives to the list
    Get-CimInstance -ClassName Win32_Volume | 
        Select-Object -ExpandProperty DriveLetter | 
        ForEach-Object { 
            $usedDriveLetters += $_ -replace ':', '' 
        }

    # Add network drives to the list
    Get-CimInstance -ClassName Win32_NetworkConnection | 
        Select-Object -ExpandProperty LocalName | 
        Foreach-Object { 
            $usedDriveLetters += $_ -replace ':', '' 
        }
    return $usedDriveLetters
}

<#
    .SYNOPSIS
        Finds the next available drive letter within a specified range.

    .DESCRIPTION
        This function determines the next available drive letter not currently
        in use by the system. It uses a specified range of ASCII values to check
        against used drive letters, returning the first available letter. If no
        letters are available within the range, it returns $null.

    .PARAMETER start
        The ASCII value representing the starting character of the range for
        drive letter assignment. Default is 65 (ASCII for 'A').

    .PARAMETER end
        The ASCII value representing the ending character of the range for drive
        letter assignment. Default is 90 (ASCII for 'Z').

    .OUTPUTS
        String
        Returns a single character string representing the next available drive
        letter, or $null if no drive letters are available within the specified range.

    .EXAMPLE
        PS> Get-NextAvailableDriveLetter
        Searches for the next available drive letter from 'A' to 'Z' and returns
        it.

    .EXAMPLE
        PS> Get-NextAvailableDriveLetter -start 67 -end 90
        Searches for the next available drive letter starting from 'C' to 'Z'.

    .NOTES
        This function is useful for scripts that need to assign drive letters
        dynamically, such as during disk partitioning or mounting operations.
#>
function Get-NextAvailableDriveLetter {
    param(
        [int]$start = 65,
        [int]$end = 90
    )
    # Get all current drive letters in use
    $usedDriveLetters = Get-UsedDriveLetters   

    # Define the range of drive letters from $start to $end
    $driveLetters = $start..$end | ForEach-Object { [char]$_ }

    # Find the first unused drive letter and return it
    foreach ($letter in $driveLetters) {
        if ($letter -notin $usedDriveLetters) {
            return $letter
        }
    }

    # Return $null if no drive letters are available
    return $null
}


<#
    .SYNOPSIS
        Displays a titled box in the console with optional key-value pair content.

    .DESCRIPTION
        This function creates an ASCII art-style box in the console, featuring a
        title and optional key-value pair lines. It formats the box to a
        specified width, automatically adjusts text alignment, and separates the
        title from the content with a line.

    .PARAMETER Title
        The text to be displayed as the title of the ASCII box. The title is
        centered at the top of the box.

    .PARAMETER Lines
        A hashtable containing key-value pairs that will be displayed inside the
        box. Keys are left-aligned, and values are right-aligned.

    .PARAMETER Width
        The total width of the ASCII box, including the border. The default
        width is 80 characters.

    .EXAMPLE
        PS> Write-AsciiBox -Title "Server Info" -Lines @{ "CPU" = "Intel"; "RAM" = "16GB" }

        Displays an ASCII box with "Server Info" as the title, and two lines
        showing CPU and RAM information.

    .EXAMPLE
        PS> Write-AsciiBox -Title "Details" -Lines @{ "Status" = "Active"; "Region" = "US East" } -Width 60

        Displays a smaller ASCII box with "Details" as the title, including
        status and region information.

    .NOTES
        This function is useful for creating visually distinct sections in
        scripts that output to the console, enhancing readability for users.
#>
function Write-AsciiBox {
    param(
        [string]$Title,
        [object]$Lines,
        [int]$Width = 80
    )
    
    $FirstLine  = '+' + ('─' * ($Width - 2)) + '+'
    $BlankLine  = '|' + (' ' * ($Width - 2)) + '|'
    $Separator  = '+' + ('─' * ($Width - 2)) + '+'
    $LastLine   = '+' + ('─' * ($Width - 2)) + '+'

    Write-Host $FirstLine
    Write-Host $BlankLine
    Write-Host ('|' + (' ' * [math]::Floor(($Width - 2 - $Title.Length) / 2)) + $Title + (' ' * [math]::Ceiling(($Width - 2 - $Title.Length) / 2)) + '|')
    Write-Host $BlankLine

    if ($Lines.Count -gt 0) {
        Write-Host $Separator
        Write-Host $BlankLine

        if ($Lines -is [hashtable]) {
            # Process the hashtable
            $longestKey = ($Lines.Keys | Measure-Object -Property Length -Maximum).Maximum
            foreach ($line in $Lines.GetEnumerator()) {
                $text = '{0}{1}: {2}' -f $line.Key, ('.' * (($longestKey + 4) - ($line.Key.tostring().length))), $line.Value
                $spaces = ($Width - 3) - $text.Length
                Write-Host ('| ' + $text + (' ' * $spaces) + '|')
            }
        } else {
            $longestKey = ($Lines | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Measure-Object -Property Length -Maximum).Maximum
            foreach ($line in $Lines) {
                $line | Get-Member -MemberType NoteProperty | ForEach-Object {
                    $text = '{0}{1}: {2}' -f $_.Name, ('.' * (($longestKey + 4) - ($_.Name.ToString().Length))), $line.($_.Name)
                    $spaces = ($Width - 3) - $text.Length
                    Write-Host ('| ' + $text + (' ' * $spaces) + '|')
                }
            }
        }
        Write-Host $BlankLine
    }

    Write-Host $LastLine
}


<#
    .SYNOPSIS
        Downloads and verifies the latest version of PowerShell Universal for a
        specified major version.

    .DESCRIPTION
        This script identifies the latest version of PowerShell Universal that
        matches a specified major version number from a predefined build type (Production or Nightly). It retrieves the MSI installer and its associated SHA256 hash from a Microsoft Azure blob storage, validates the hash to ensure the download's integrity, and saves the installer to a specified directory.

    .PARAMETER BuildType
        The type of build to download. Accepts 'Production' or 'Nightly'.
        Default is 'Production'.

    .PARAMETER MajorVersion
        The major version number of PowerShell Universal to download. Currently
        supports versions '4' and '5'. Default is '4'.

    .PARAMETER DownloadDir
        The directory to which the MSI file will be downloaded. Default is the
        'software' directory under 'vagrant' on the system drive.

    .EXAMPLE
        PS> Get-LatestPowerShellUniversal -BuildType 'Production' -MajorVersion '5'
        Downloads the latest production build of PowerShell Universal version 5.

    .EXAMPLE
        PS> .Get-LatestPowerShellUniversal -BuildType 'Nightly' -MajorVersion '4' -DownloadDir 'D:\downloads'
        Downloads the latest nightly build of PowerShell Universal version 4 to the specified directory on the D: drive.

    .NOTES
        The script requires internet connectivity. It also needs permissions to
        write to the specified directory. Ensure execution policies allow script
        running.
#>
function Get-LatestPowerShellUniversal {
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet('Production', 'Nightly')]
        [string] $BuildType = 'Production',

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('4', '5')]
        [string] $MajorVersion = '4',

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $DownloadDir = ('{0}:\vagrant\software' -f $env:SystemDrive)
    )

    # Don't change anything below this line
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $pattern    = '^production\/[\d\.]+\/PowerShellUniversal[\d\.]+msi'
    $baseUri    = 'https://imsreleases.blob.core.windows.net/{0}' -f $(if ($BuildType -eq 'Nightly') { 'universal-nightly' } else { 'universal' })
    $versUri    = '{0}/production/v{1}-version.txt' -f $baseUri, $MajorVersion
    $xmlUri     = '{0}?restype=container&comp=list' -f $baseUri
    $downloads  = @{ Name = ''; Msi = ''; Hash = ''}

    # The XML response from the blob storage API is not well-formed, so we need to
    # clean it up by removing non-word characters from the beginning of the response
    $content  = Invoke-RestMethod -Uri $xmlUri 
    $response = [regex]::replace($content, "^[^<]+<", "<")

    # Get the latest version from the version file if it's not known. This saves
    # us from having to do date math to determine the latest version
    $latestVer  = Invoke-RestMethod -Uri $versUri -UseBasicParsing

    # Parse the XML response. Try/Catch here to handle any parsing errors. If XML
    # parsing fails, the script will exit with an error.
    try {
        $releases = [xml]$response
    } catch {
        Write-Error "Failed to parse XML response: $response"
        exit 1
    }


    # Determine the target files based on the latest version or the latest date
    if ($latestVer) {
        # No need to do any date math if the latest version is known
        $files = $releases.EnumerationResults.Blobs.Blob | 
                    Where-Object { $_.Name -match $latestVer -and $_.Name -match $pattern }
    } else {
        # If the latest version is known, determine target files by date
        $files = $releases.EnumerationResults.Blobs.Blob | 
                    Where-Object Name -match $pattern | 
                    Select-Object -Property Name, Url, @{n="LastModified";e={(Get-Date $_.Properties.'Last-Modified')}} | 
                    Sort-Object -Property LastModified -Descending | 
                    Select-Object -First 2
        $latestVer = $files[0].Name.split('/')[1]

    }

    if ($files) {
        $Msi = $files | Where-Object Name -notmatch 'sha256'
        $HashUrl = $files | Where-Object Name -match 'sha256' | Select-Object -ExpandProperty Url
        $downloads.Hash = (Invoke-RestMethod -Uri $HashUrl) -replace '\s', ''
        $downloads.Name = ($Msi.Name -split '/')[-1]
        $downloads.Url  = $Msi.Url
    } else {
        Write-Error "No files found matching the pattern: $pattern"
        exit 1
    }

    # Download the MSI file and the SHA256 hash file
    try {
        $MsiFilePath = Join-Path $DownloadDir "$(($downloads.Name -split '/')[-1])"
        $downloads.Add('LocalPath', $MsiFilePath)

        Write-Information "Downloading $($downloads.Name) to $MsiFilePath"
        
        if (Test-Path $MsiFilePath) {
            Remove-Item $MsiFilePath -Force
        }

        Invoke-WebRequest -Uri $downloads.Url -OutFile $MsiFilePath -UseBasicParsing
        $DlHash = Get-FileHash -Path $MsiFilePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash

        if ($DlHash -eq $downloads.Hash) {
            Write-Information "Downloaded $($downloads.Name) successfully"
            return $downloads
        } else {
            throw "Failed to download $($downloads.Name): SHA256 hash mismatch"
        }
    } catch {
        Write-Error "Failed to download $($downloads.Name): $_"    
    }
}