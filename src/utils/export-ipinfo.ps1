<#
    .SYNOPSIS
        Gathers network IP address information and exports it to a CSV file.

    .DESCRIPTION
        This script collects the IP address information for Ethernet interfaces
        on the local machine and appends it to a CSV file located in the Vagrant
        directory on the system drive. If the file already exists, the script
        ensures that no duplicate entries for the same computer are added.

    .PARAMETER path
        Specifies the path where the CSV file will be stored. This is dynamically
        constructed using the system drive.

    .PARAMETER Output
        Holds the output data which includes the computer name, IP address, and
        interface alias of Ethernet adapters.

    .EXAMPLE
        PS> .\ScriptName.ps1
        Executes the script to append the local machine's Ethernet IP information to 'vmnetinfo.csv' on the system drive under the 'vagrant' directory.

    .NOTES
        Ensure that the script is run with appropriate permissions to access network configuration and write to the target file path.
#>

$path = Join-Path $env:SystemDrive '\vagrant\vmnetinfo.csv'
$Output = Get-NetIPAddress | 
            Where-Object { 
                $_.InterfaceAlias -Match 'Ethernet' -AND $_.AddressFamily -eq 'IPv4'
            } | 
            Select-Object @{
                n="Computername"; 
                e={$env:COMPUTERNAME}
            }, IPAddress, InterfaceAlias 

if (Test-Path $path) {
    $csv = Import-Csv -Path $path
    $csv | Where-Object Computername -ne $env:COMPUTERNAME | Export-Csv -Path $path -Append -NoTypeInformation
}

$Output | Export-Csv -Path $path -Append -NoTypeInformation