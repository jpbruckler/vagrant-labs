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

$start = Get-Date
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')
Write-ProvisionScriptHeader
$rc = 0

$Disks = Get-Disk
$Volumes = Get-CimInstance -ClassName Win32_Volume

Write-Information -MessageData "Disk information:"
$Disks | Select-Object Number, FriendlyName, OperationalStatus, PartitionStyle, @{n='Size';e={$u = 'gb'; $sz = $_.Size / 1gb; if ($sz -gt 1000) { $sz = $_.Size/1tb; $u = 'tb' }; '{0:N2}{1}' -f $sz,$u }} | Format-Table -AutoSize

Write-Information -MessageData "Volume information:"
$Volumes | Select-Object DriveLetter, Label, DriveType | Format-Table -AutoSize

# Check if the specified drive letter is already in use by a CD-ROM drive
# CD-ROM has DriveType = 5
Write-Information -MessageData "Checking if drive letter $DriveLetter is already in use..."
if ($Volumes.DriveLetter -contains "${DriveLetter}:") {
    $usedVolume = $Volumes | Where-Object { $_.DriveLetter -eq "${DriveLetter}:" }
    if ($usedVolume.DriveType -eq 5) {
        Write-Information -MessageData "`tDrive letter $DriveLetter is already in use by a CD-ROM drive."
        Write-Information -MessageData "`tAttempting to reassign CD-ROM drive letters."
        $cdDriveLetter = Get-NextAvailableDriveLetter -start 88 -end 68

        Write-Information -MessageData "`tReassigning CD-ROM drive letter $cdDriveLetter to CD-ROM drive $($usedVolume.Name)..."
        $result = Set-CDRomDriveLetter -DriveLetter $cdDriveLetter -Drive $usedVolume

        if ($result) {
            Write-Information -MessageData "`tDrive letter $cdDriveLetter has been reassigned to CD-ROM drive $($usedVolume.Name)."
        }
        else {
            Write-Error -Message "`tFailed to reassign drive letter $cdDriveLetter to CD-ROM drive $($usedVolume.Name)."
            Write-Information -MessageData "`tNext available drive letter will be assigned to new partitions."
            $DriveLetter = "{0}" -f (Get-NextAvailableDriveLetter -start 68 -end 90)
        }
    }
    else {
        Write-Error -Message "`tDrive letter $DriveLetter is already in use by a non-CD-ROM drive."
        Write-Information -MessageData "`tNext available drive letter will be assigned to new partitions."
        $DriveLetter = "{0}" -f (Get-NextAvailableDriveLetter -start 68 -end 90)
    }
}


# Get all disks that are either Offline or have a RAW partition style
Write-Information -MessageData "Checking for offline or raw disks..."
$targetDisks = $Disks | Where-Object { $_.PartitionStyle -eq 'RAW' -OR $_.OperationalStatus -eq 'Offline' } 
if ($null -ne $targetDisks) {
    foreach ($disk in $targetDisks) {
        Write-Host "Initializing disk $($disk.Number)..."

        try {
            # Set the disk to Online
            Write-Information -MessageData "`tSetting disk $($disk.Number) to Online..."
            Set-Disk -Number $disk.Number -IsOffline $false
        }
        catch {
            Write-Error "Failed to set the disk to Online: $_"
            $rc = 1
        }

        try {
            # Initialize the disk with a GPT partition style
            Write-Information -MessageData "`tInitializing disk $($disk.Number) with a GPT partition style..."
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT

            # Create a new partition that uses the entire disk
            Write-Information -MessageData "`tCreating a new partition on Disk $($disk.Number)..."
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
                Write-Information -MessageData "`tPartition $($summary.PartitionNumber) on Disk $($summary.DiskNumber) is $($summary.Size) and will be assigned drive letter $DriveLetter."
                Set-Partition -NewDriveLetter $DriveLetter
            }
        }
        catch {
            Write-Error "Failed to initialize the disk with a GPT partition style: $_"
            $rc = 1
        }

        try {
            # Format the partition as exFAT
            Format-Volume -Partition $partition -FileSystem exFAT -Confirm:$false
            Write-Host "Disk $($disk.Number) is now online, initialized, and formatted as exFAT."
        }
        catch {
            Write-Error "Failed to format the partition as exFAT: $_"
            $rc = 1
        }
    }
}
else {
    Write-Host "`tNo offline disks found, nothing to do."
}

$end = Get-Date
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).Seconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit $rc