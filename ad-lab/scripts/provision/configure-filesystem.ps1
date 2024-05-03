$start = Get-Date
$InformationPreference = "Continue"
. $PSScriptRoot\..\utils\deploy-utils.ps1

Write-ProvisionScriptHeader
Write-Information -MessageData "Creating directories for tools and logs.."

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
        }
    } else {
        Write-Information -MessageData "`tDirectory '$Directory' already exists."
    }
}
$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0