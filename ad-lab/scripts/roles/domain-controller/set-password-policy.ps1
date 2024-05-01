<#
    .SYNOPSIS
        Sets the default password and account lockout policies for a specified
        Active Directory domain.

    .DESCRIPTION
        This script configures various password policy settings for an Active
        Directory domain. It sets minimum and maximum password age limits, password history count, and account lockout parameters such as duration, observation window, and threshold.

    .PARAMETER DomainName
        The name of the domain for which to set the password policies. Default
        is "dev.local".

    .EXAMPLE
        PS> .\ScriptName.ps1 -DomainName 'dev.local'
        Configures the password and lockout policies for the 'dev.local' domain
        with predefined settings.

    .EXAMPLE
        PS> .\ScriptName.ps1
        Applies default password and lockout policies to the 'dev.local' domain.

    .NOTES
        This script requires Active Directory PowerShell module and must be run
        with administrative privileges.

        Ensure that you have the necessary permissions to modify domain policies
        before running this script.
#>
param
(
    [string]$DomainName = "dev.local"
)
Set-ADDefaultDomainPasswordPolicy $DomainName -MinPasswordAge 1.00:00:00
Set-ADDefaultDomainPasswordPolicy $DomainName -MaxPasswordAge 90.00:00:00
Set-ADDefaultDomainPasswordPolicy $DomainName -PasswordHistoryCount 6
Set-ADDefaultDomainPasswordPolicy $DomainName -LockoutDuration 00:30:00
Set-ADDefaultDomainPasswordPolicy $DomainName -LockoutObservationWindow 00:30:00
Set-ADDefaultDomainPasswordPolicy $DomainName -LockoutThreshold 6
