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

function Write-AsciiBox {
    param(
        [string]$Title,
        [hashtable]$Lines,
        [int]$Width = 80
    )
    
    $FirstLine  = '┌' + ('─' * ($Width - 2)) + '┐'
    $BlankLine  = '│' + (' ' * ($Width - 2)) + '│'
    $Separator  = '├' + ('─' * ($Width - 2)) + '┤'
    $LastLine   = '└' + ('─' * ($Width - 2)) + '┘'

    Write-Host $FirstLine
    Write-Host $BlankLine
    Write-Host ('│' + (' ' * [math]::Floor(($Width - 2 - $Title.Length) / 2)) + $Title + (' ' * [math]::Ceiling(($Width - 2 - $Title.Length) / 2)) + '│')
    Write-Host $BlankLine

    if ($Lines.Count -gt 0) {
        Write-Host $Separator
        Write-Host $BlankLine

        $longestKey = ($Lines.Keys | Measure-Object -Property Length -Maximum).Maximum

        # Process the hashtable
        foreach ($line in $Lines.GetEnumerator()) {
            $text = '{0}{1}: {2}' -f $line.Key, ('.' * (($longestKey + 4) - ($line.Key.tostring().length))), $line.Value
            $spaces = ($Width - 3) - $text.Length
            Write-Host ('│ ' + $text + (' ' * $spaces) + '│')
        }
        Write-Host $BlankLine
    }

    Write-Host $LastLine
}