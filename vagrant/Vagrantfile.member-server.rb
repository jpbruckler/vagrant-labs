srv.vm.provision "shell", path: "#{role_scripts}/join-domain.ps1", privileged: true, env: env
srv.vm.provision "shell", reboot: true