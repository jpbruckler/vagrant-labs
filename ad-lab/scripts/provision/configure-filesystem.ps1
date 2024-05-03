$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader -ScriptName 'configure-filesystem.ps1'
Write-Information -MessageData "Creating directories for tools and logs.."

$rc = 0
$Directories = @("C:\tools", "C:\tmp", "C:\tmp\logs")
foreach ($Directory in $Directories) {
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        Write-Information -MessageData "`tCreating directory $Directory"
        try {
            $Path = Split-Path -Path $Directory -Parent
            $Name = Split-Path -Path $Directory -Leaf
            $null = New-Item -Path $Path -Name $Name -ItemType "Directory" -Force -ErrorAction Stop
            Write-Information -MessageData "`tDirectory '$Directory' created."
        } catch {
            Write-Error -Message "Failed to create directory '$Directory'."
            $rc = 1
        }
    } else {
        Write-Information -MessageData "`tDirectory '$Directory' already exists."
    }
}
$end = Get-Date
Write-Information -MessageData "Time taken: $((New-TimeSpan -Start $start -End $end).Seconds) seconds."
Write-Information -MessageData "Filesystem configuration completed."
exit $rc