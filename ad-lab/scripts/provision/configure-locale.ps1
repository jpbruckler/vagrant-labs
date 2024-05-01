param(
    [string] $Locale = "en-US",
    [string] $Timezone = "Eastern Standard Time"
)

$availableLocales   = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures)| Select-Object -ExpandProperty Name
$currentLocale      = Get-WinSystemLocale
$availableTimezones = Get-TimeZone -ListAvailable | Select-Object -ExpandProperty Id

if ($Locale -and ($Locale -in $availableLocales) -and ($Locale -ne $currentLocale)){
    try {
        Set-WinSystemLocale -SystemLocale $Locale -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to set locale to $Locale"
    }
}

if ($Timezone -and ($Timezone -in $availableTimezones) -and ($Timezone -ne (Get-TimeZone).Id)) {
    try {
        Set-TimeZone -Id $Timezone -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to set timezone to $Timezone"
    }
}

# Exit with a 0 status, as this script is not critical to the success of the
# provisioning process
exit 0