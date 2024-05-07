irms_account  = server['irms']&.[]('service_account')  || nil # safe navigation operator; set to nil if not found
irms_password = server['irms']&.[]('account_pw') || nil  # safe navigation operator; set to nil if not found
srv.vm.provision "shell", path: "#{default_scripts}/add-rsatadposh.ps1", privileged: true
srv.vm.provision "shell", path: "#{role_scripts}/install-psmodules.ps1", privileged: true
srv.vm.provision "shell", reboot: true

# Create and configure service account
if server.key?("irms") && server["irms"].key?("service_account") && server["irms"].key?("account_pw")
    srv.vm.provision "shell", path: "#{role_scripts}/create-domainserviceaccount.ps1", privileged: true, args: "'#{irms_account}' '#{irms_password}'"
    srv.vm.provision "shell", path: "#{role_scripts}/grant-serviceaccountrights.ps1", privileged: true, args: irms_account
end

# Download & Install PowerShell Universal
srv.vm.provision "shell", path: "#{role_scripts}/download-powershelluniversal.ps1", privileged: false
srv.vm.provision "shell", path: "#{role_scripts}/create-pwshufirewallrule.ps1", privileged: true
srv.vm.provision "shell", path: "#{role_scripts}/install-powershelluniversal.ps1", privileged: true, args: "'#{irms_account}' '#{irms_password}'"
srv.vm.provision "shell", reboot: true