<#
    .SYNOPSIS
        Initializes and configures offline or raw disks and reassigns CD-ROM
        drive letters if needed.

    .DESCRIPTION
        This script is designed to run on host machines during the deployment of
        virtual machines using Vagrant. It checks for offline or raw disks,
        initializes them with a GPT partition, assigns drive letters, and
        formats them. Additionally, it reassigns drive letters of CD-ROM drives
        that remain from Vagrant box images to ensure no conflicts.

    .PARAMETER DriveLetter
        Specifies the preferred drive letter for new partitions. If this drive
        letter is in use, the script will select the next available letter
        starting from D:.
        
        Default is 'D'.

    .EXAMPLE
        PS> .\initialize-disks.ps1
        Runs the script using the default drive letter (D:).

    .EXAMPLE
        PS> .\initialize-disks.ps1 -DriveLetter 'E'
        Runs the script and attempts to set 'E' as the drive letter for new partitions, if available.

    .NOTES
        Requires administrative privileges to modify disk partitions and drive letters.
        This script includes error handling to stop execution upon encountering errors during disk operations.
#>

param(
    [string] $DriveLetter = "D"
)

$ErrorActionPreference = "Stop"

. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\psutils.ps1')



# Some vagrant box images include CD-ROM drives that are not removed when the
# box is packaged. This script will reletter any CD-ROM drives to the next
# available drive letter, starting from Z: and working backwards to A:.
if ((Get-UsedDriveLetters) -contains $DriveLetter) {
    Write-Host "Drive letter $DriveLetter is already in use."
    Write-Host "Checking for CD-ROM drives..."
    $CdRoms = Get-CimInstance -ClassName Win32_Volume -Filter "DriveType = 5"


    if ($CdRoms) {
        foreach ($drive in $CdRoms) {
            $driveLetter = "{0}:" -f (Get-NextAvailableDriveLetter)
            Write-Host "Relettering CD-ROM drive $($drive.Name) to $driveLetter"
            $drive | Set-CimInstance -Property @{ DriveLetter = "$driveLetter" }
        }
    }
    else {
        Write-Host "No CD-ROM drives found. Moving on to virtual disks."
    }
}


# Get all disks that are either Offline or have a RAW partition style
$targetDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -OR $_.OperationalStatus -eq 'Offline' } 
if ($null -ne $targetDisks) {
    foreach ($disk in $targetDisks) {
        Write-Host "Initializing disk $($disk.Number)..."

        try {
            # Set the disk to Online
            Set-Disk -Number $disk.Number -IsOffline $false
        }
        catch {
            Write-Error "Failed to set the disk to Online: $_"
            exit 1
        }

        try {
            # Initialize the disk with a GPT partition style
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT

            # Create a new partition that uses the entire disk
            $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize

            # Set the drive letter for the partition to $DriveLetter for data drive
            $partition | Where-Object Type -eq 'Basic' | Foreach-Object {
                $DriveLetter = "{0}" -f (Get-NextAvailableDriveLetter -start 68 -end 90)
                if (($_.Size / 1gb) -gt 1024) { 
                    $size = '{0:N2} TB' -f ($_.Size / 1tb) 
                }
                else { 
                    $size = '{0:N2} GB' -f ($_.Size / 1gb) 
                }
                $summary = [PSCustomObject]@{
                    DiskNumber      = $disk.Number
                    PartitionNumber = $_.PartitionNumber
                    Size            = $size
                    DriveLetter     = $DriveLetter
                }
                Write-Host "Partition $($summary.PartitionNumber) on Disk $($summary.DiskNumber) is $($summary.Size) and will be assigned drive letter $DriveLetter."
                Set-Partition -NewDriveLetter $DriveLetter
            }
        }
        catch {
            Write-Error "Failed to initialize the disk with a GPT partition style: $_"
            exit 1
        }

        try {
            # Format the partition as exFAT
            Format-Volume -Partition $partition -FileSystem exFAT -Confirm:$false
            Write-Host "Disk $($disk.Number) is now online, initialized, and formatted as exFAT."
        }
        catch {
            Write-Error "Failed to format the partition as exFAT: $_"
            exit 1
        }
    }
}
else {
    Write-Host "No offline disks found."
}
