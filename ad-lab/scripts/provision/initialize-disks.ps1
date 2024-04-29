param(
    [string] $DriveLetter = "D"
)

$ErrorActionPreference = "Stop"

function Get-UsedDriveLetters {
    # Get all current drive letters in use
    $usedDriveLetters = Get-CimInstance -ClassName Win32_Volume | Select-Object -ExpandProperty DriveLetter
    return $usedDriveLetters
}

function Get-NextAvailableDriveLetter {
    # Get all current drive letters in use
    $usedDriveLetters = Get-UsedDriveLetters   

    # Define the range of drive letters from Z to A
    $driveLetters = 90..65 | ForEach-Object { [char]$_ }

    # Find the first available drive letter from Z to A
    foreach ($letter in $driveLetters) {
        if ($letter -notin $usedDriveLetters) {
            return $letter + ":"
        }
    }

    # Return $null if no drive letters are available
    return $null
}

if (Get-UsedDriveLetters -contains $DriveLetter) {
    Write-Host "Drive letter $DriveLetter is already in use."
    $CdRoms = Get-CimInstance -ClassName Win32_Volume -Filter "DriveType = 5"
    if ($CdRoms) {
        foreach ($drive in $CdRoms) {
            $driveLetter = Get-NextAvailableDriveLetter
            $drive | Set-CimInstance -Property @{ DriveLetter = "$driveLetter" }
        }
    } else {
        Write-Host "No CD-ROM drives found."
        Write-Host "Getting next available drive letter..."
        $DriveLetter = Get-NextAvailableDriveLetter

        if ($null -eq $DriveLetter) {
            Write-Error "No available drive letters found."
            exit 1
        } else {
            Write-Host "Next available drive letter is $DriveLetter."
        }
    }
}


# Get all disks that are Offline
$disks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Select-Object -First 1

if ($null -ne $disks) {
    foreach ($disk in $disks) {
        Write-Host "Initializing disk $($disk.Number)..."
        try {
            # Set the disk to Online
            Set-Disk -Number $disk.Number -IsOffline $false
        } catch {
            Write-Error "Failed to set the disk to Online: $_"
            exit 1
        }

        try {
            # Initialize the disk with a GPT partition style
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT

            # Create a new partition that uses the entire disk
            $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize

            # Set the drive letter for the partition to $DriveLetter for data drive
            $partition | Set-Partition -NewDriveLetter $DriveLetter
        } catch {
            Write-Error "Failed to initialize the disk with a GPT partition style: $_"
            exit 1
        }

        try {
            # Format the partition as exFAT
            Format-Volume -Partition $partition -FileSystem exFAT -Confirm:$false
            Write-Host "Disk $($disk.Number) is now online, initialized, and formatted as exFAT."
        } catch {
            Write-Error "Failed to format the partition as exFAT: $_"
            exit 1
        }
    }
} else {
    Write-Host "No offline disks found."
}
