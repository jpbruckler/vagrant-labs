function Get-NextAvailableDriveLetter {
    # Get all current drive letters in use
    $usedDriveLetters = (Get-Volume | Select-Object -ExpandProperty DriveLetter) + (Get-Partition | Select-Object -ExpandProperty DriveLetter)

    # Define the range of drive letters from X to A
    # Avoid Z because Vagrant. Avoid Y because it's likely a network drive.
    $driveLetters = 88..65 | ForEach-Object { [char]$_ }

    # Find the first available drive letter from Z to A
    foreach ($letter in $driveLetters) {
        if ($letter -notin $usedDriveLetters) {
            return $letter + ":"
        }
    }

    # Return $null if no drive letters are available
    return $null
}

$CdRoms = Get-CimInstance -ClassName Win32_Volume -Filter "DriveType = 5"

foreach ($drive in $CdRoms) {
    $driveLetter = Get-NextAvailableDriveLetter
    $drive | Set-CimInstance -Property @{ DriveLetter = "$driveLetter" }
}