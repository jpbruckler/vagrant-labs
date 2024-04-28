$ErrorActionPreference = "Stop"

# Get all disks that are Offline
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Select-Object -First 1

if ($disk -ne $null) {
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

        # Set the drive letter for the partition to "D" for data drive
        $partition | Set-Partition -NewDriveLetter D
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
} else {
    Write-Host "No offline disks found."
}
