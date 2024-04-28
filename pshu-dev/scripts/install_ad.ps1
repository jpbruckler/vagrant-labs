([WMIClass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DomainName) | Out-Null
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools