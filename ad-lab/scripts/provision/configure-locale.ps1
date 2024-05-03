param(
    [string] $Locale = "en-US",
    [string] $Timezone = "Eastern Standard Time"
)
$start = Get-Date
$InformationPreference = "Continue"
. (Join-Path $env:SystemDrive 'vagrant\scripts\utils\deploy-utils.ps1')

Write-ProvisionScriptHeader

$availableLocales   = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures)| Select-Object -ExpandProperty Name
$availableTimezones = Get-TimeZone -ListAvailable | Select-Object -ExpandProperty Id
$currentLocale      = Get-WinSystemLocale
$currentTimezone    = (Get-TimeZone).Id

Write-Information -MessageData "Current locale: $currentLocale"
Write-Information -MessageData "Current timezone: $currentTimezone"

if ($Locale -and ($Locale -in $availableLocales) -and ($Locale -ne $currentLocale)){
    try {
        Write-Information -MessageData "`tSetting locale to $Locale"
        Set-WinSystemLocale -SystemLocale $Locale -ErrorAction Stop
    }
    catch {
        Write-Warning "`tFailed to set locale to $Locale"
    }
} else {
    Write-Information -MessageData "`tLocale is already set to $currentLocale, or $Locale is not a valid locale."
}

if ($Timezone -and ($Timezone -in $availableTimezones) -and ($Timezone -ne $currentTimezone)) {
    Write-Information -MessageData "`tSetting timezone to $Timezone"
    try {
        Set-TimeZone -Id $Timezone -ErrorAction Stop
    }
    catch {
        Write-Warning "`tFailed to set timezone to $Timezone"
    }
} else {
    Write-Information -MessageData "`tSystem timezone is already set to $Timezone, or $Timezone is not a valid timezone."
}

$end = Get-Date
Write-Information -MessageData "Time taken: $(($end - $start).TotalSeconds) seconds."
Write-Information -MessageData "$($MyInvocation.MyCommand.Name) completed."
exit 0