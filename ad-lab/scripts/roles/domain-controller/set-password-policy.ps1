param
(
    [string]$DomainName = "example.local"
)
Set-ADDefaultDomainPasswordPolicy $DomainName -MinPasswordAge 1.00:00:00
Set-ADDefaultDomainPasswordPolicy $DomainName -MaxPasswordAge 90.00:00:00
Set-ADDefaultDomainPasswordPolicy $DomainName -PasswordHistoryCount 6
Set-ADDefaultDomainPasswordPolicy $DomainName -LockoutDuration 00:30:00
Set-ADDefaultDomainPasswordPolicy $DomainName -LockoutObservationWindow 00:30:00
Set-ADDefaultDomainPasswordPolicy $DomainName -LockoutThreshold 6
