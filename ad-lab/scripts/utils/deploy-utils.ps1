function Write-ProvisionScriptHeader {
    <#
    .SYNOPSIS
        Writes a header for a provisioning script.

    .DESCRIPTION
        This function writes a header to the console for a provisioning script.
        The header includes the script name, a timestamp, and a description.

    .PARAMETER ScriptName
        The name of the provisioning script.

    .PARAMETER Description
        A brief description of the provisioning script.

    .EXAMPLE
        Write-ProvisionScriptHeader -ScriptName "configure-filesystem.ps1" -Description "Creates directories for tools and logs"

        Writes a header for the "configure-filesystem.ps1" script with the specified description.
    #>
    param (
        [Parameter(Mandatory = $false)]
        [string] $ScriptName,
        [string] $Title = "Vagrant Provisioning Script"
    )

    if (-not $ScriptName) {
        $ScriptName = $MyInvocation.PSCommandPath | Split-Path -Leaf
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff K"
    
    $Lines = @{
        "Script" = $ScriptName
        "Timestamp" = $timestamp
    }
    Write-AsciiBox -Title $Title -Lines $Lines
}

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

function Set-CDRomDriveLetter {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DriveLetter,
        [Parameter(Mandatory = $true)]
        [CimInstance] $Drive
    )

    if (-not($DriveLetter.EndsWith(':'))) {
        $DriveLetter = "${DriveLetter}:"
    }
    Write-Verbose "Attempting to reassign CD-ROM drive letter '$DriveLetter' to CD-ROM drive '$($Drive.Name)'..."
    
    try {
        $Drive | Set-CimInstance -Property @{ DriveLetter = "$DriveLetter" } -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error -Message "Failed to reletter drive '$($Drive.Name)': $_"
        return $false
    }
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
        [hashtable]$Lines,
        [int]$Width = 80
    )
    
    $FirstLine  = '+' + ('-' * ($Width - 2)) + '+'
    $BlankLine  = '|' + (' ' * ($Width - 2)) + '|'
    $Separator  = '+' + ('-' * ($Width - 2)) + '+'
    $LastLine   = '+' + ('-' * ($Width - 2)) + '+'

    Write-Host $FirstLine
    Write-Host $BlankLine
    Write-Host ('|' + (' ' * [math]::Floor(($Width - 2 - $Title.Length) / 2)) + $Title + (' ' * [math]::Ceiling(($Width - 2 - $Title.Length) / 2)) + '|')
    Write-Host $BlankLine

    if ($Lines.Count -gt 0) {
        Write-Host $Separator
        Write-Host $BlankLine

        $longestKey = ($Lines.Keys | Measure-Object -Property Length -Maximum).Maximum

        # Process the hashtable
        foreach ($line in $Lines.GetEnumerator()) {
            $text = '{0}{1}: {2}' -f $line.Key, ('.' * (($longestKey + 4) - ($line.Key.tostring().length))), $line.Value
            $spaces = ($Width - 3) - $text.Length
            Write-Host ('| ' + $text + (' ' * $spaces) + '|')
        }
        Write-Host $BlankLine
    }

    Write-Host $LastLine
}

<#
.SYNOPSIS
    Retrieves information about the latest PowerShell Universal installer for a
    specified build type and version.

.DESCRIPTION
    This function queries a specified Azure Blob storage to find the latest
    available installer for PowerShell Universal based on the build type, major
    version, and installer type. It provides detailed information about the
    installer file, including name, URL, version, last modified date, and SHA256
    hash.

.PARAMETER BuildType
    Specifies the build type of PowerShell Universal to retrieve. Valid options
    are 'Production' and 'Nightly'.
    Default is 'Production'.

.PARAMETER MajorVersion
    Specifies the major version of PowerShell Universal to target. Valid options
    are '4' and '5'.
    
    Default is '4'.

.PARAMETER InstallerType
    Specifies the type of installer file to retrieve. Valid options include 'msi',
    'zip', 'desktop', 'eventhub', 'lnxX64', 'lnxARM', 'lnxARM64', 'macOS', and 
    'macOSARM64'.
    
    Default is 'msi'.

.EXAMPLE
    PS> Get-PwshUniversalInstallerInfo -BuildType 'Production' -MajorVersion '5' -InstallerType 'msi'
    Retrieves information about the latest PowerShell Universal MSI installer for
    version 5 from the Production builds.

.EXAMPLE
    PS> Get-PwshUniversalInstallerInfo -BuildType 'Nightly' -InstallerType 'zip'
    Retrieves information about the latest PowerShell Universal ZIP file from the
    Nightly builds for the default major version 4.

.NOTES
    Ensure you have connectivity to the specified Azure Blob storage and proper
    permissions to access the data. The function uses the Invoke-RestMethod 
    cmdlet to pull data from the internet, which may require proxy configuration
    in some environments.
#>

function Get-PwshUniversalInstallerInfo {
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet('Production', 'Nightly')]
        [string] $BuildType = 'Production',

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('4', '5')]
        [string] $MajorVersion = '4',

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('msi', 'zip', 'desktop', 'eventhub', 'lnxX64', 'lnxARM', 'lnxARM64', 'macOS', 'macOSARM64')]
        [string] $InstallerType = 'msi'
    )

    begin {
        $patternTable = [PSCustomObject] @{
            'msi'       = '\/PowerShellUniversal\.(\d{1}\.\d{1,2}\.\d{1,4})\.msi'
            'zip'       = '\/Universal\.win7-x64\.(\d{1}\.\d{1,2}\.\d{1,4})\.zip'
            'desktop'   = '\/PowerShellUniversal\.Desktop\.(\d{1}\.\d{1,2}\.\d{1,4})\.exe'
            'eventhub'  = '\/PowerShellUniversal\.EventHubClient\.(\d{1}\.\d{1,2}\.\d{1,4})\.msi'
            'lnxX64'    = '\/Universal\.linux-x64\.(\d{1}\.\d{1,2}\.\d{1,4})\.zip'
            'lnxARM'    = '\/Universal\.linux-arm\.(\d{1}\.\d{1,2}\.\d{1,4})\.zip'
            'lnxARM64'  = '\/Universal\.linux-arm64\.(\d{1}\.\d{1,2}\.\d{1,4})\.zip'
            'macOS'     = '\/Universal\.osx-x64\.(\d{1}\.\d{1,2}\.\d{1,4})\.zip'
            'macOSARM64'= '\/Universal\.osx\.12-arm64\.(\d{1}\.\d{1,2}\.\d{1,4})\.zip'
        }
    }

    process{
        $buildStub = 'universal'
        if ($BuildType -eq 'Nightly') {
            $buildStub = 'universal-nightly'
        }

        $pattern = $patternTable.$InstallerType
        $baseUri = 'https://imsreleases.blob.core.windows.net/{0}' -f $buildStub
        $xmlUri  = '{0}?restype=container&comp=list' -f $baseUri
        $Output  = [PSCustomObject]@{
            Name = $null
            Url = $null
            Version = $null
            LastModified = $null
            Hash = $null
        }
        [xml]$response   = [regex]::replace((Invoke-RestMethod -Uri $xmlUri), "^[^<]+<", "<")
        $file = $response.EnumerationResults.Blobs.Blob | 
                    Select-Object -Property Name, Url, @{n="LastModified";e={(Get-Date $_.Properties.'Last-Modified')}} | 
                    Sort-Object -Property LastModified -Descending | 
                    Where-Object Name -match $pattern |
                    Where-Object Name -notmatch 'sha256' |
                    Select-Object -First 1
        
        $hashUrl = '{0}.sha256' -f $file.Url
        $hashVal = Invoke-RestMethod -Uri $hashUrl -SkipHttpErrorCheck
        if ($hashVal -match '<Error>') {
            $hashVal = $null
        } else {
            $hashVal = $hashVal -replace '\s', ''
        }
        $Output.Hash            = $hashVal
        $Output.Name            = $file.Name -split '/' | Select-Object -Last 1
        $Output.Url             = $file.Url
        $Output.Version         = $file.Name -split '/' | Select-Object -Index 1
        $Output.LastModified    = $file.LastModified
        return $Output
    }
}