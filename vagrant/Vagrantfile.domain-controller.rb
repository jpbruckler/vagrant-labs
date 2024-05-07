role_scripts  = "src/roles/domain-controller/scripts"
safe_mode_pwd = vars['safemodepassword'] || env['safemodepassword'] || 'Password1234!'
lab_domain    = vars['domainname'] || env['labdomain'] || 'lab.local'
lab_ntb_name  = vars['netbiosname'] || env['lablabnetbiosname'] || 'LAB'
srv.vm.provision "shell", path: "#{role_scripts}/install-adds.ps1", privileged: true, args: "'#{lab_domain}' '#{lab_ntb_name}' '#{safe_mode_pwd}'", env: env
srv.vm.provision "shell", reboot: true
srv.vm.provision "shell", path: "#{role_scripts}/importusers.ps1", privileged: false, env: env