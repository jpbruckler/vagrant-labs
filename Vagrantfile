VAGRANTFILE_API_VERSION = "2"

require 'yaml'

# Load the provision.yaml file
conf    = YAML.load_file(File.join(File.dirname(__FILE__), 'provision.yaml'))
servers = conf['servers']
vars    = conf['vars']
env     = conf['env']
default_scripts = "src/roles/default/scripts"
utils_scripts   = "src/utils"
vdiskmgr_path   = '"C:\\Program Files (x86)\\VMware\\VMware Workstation\\vmware-vdiskmanager.exe"'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    servers.each do |server|
        config.vm.define server["name"] do |srv|
            srv.vm.box      = server["box"]
            srv.vm.hostname = server["name"]

            # Use the plaintext WinRM transport and force it to use basic authentication.
            # NB this is needed because the default negotiate transport stops working
            #    after the domain controller is installed.
            #    see https://groups.google.com/forum/#!topic/vagrant-up/sZantuCM0q4
            srv.winrm.transport = :plaintext
            srv.winrm.basic_auth_only = true

            srv.vm.provider "vmware_desktop" do |vm|
                vm.vmx["cpuid.coresPerSocket"]  = "1"
                vm.vmx["memsize"]               = server['memory'] || "1024"
                vm.vmx["numvcpus"]              = server['cpus'] || "2"
                vm.gui                          = server['gui'] || true

                if vars['provider']&.[]('vmware')&.[]('clone_directory')
                    vm.clone_directory = "#{vars['provider']['vmware']['clone_directory']}\\#{server['name']}"
                end

                # Configure VMWare Provider to create DHCP reservations
                if server.key?("staticip")
                    vm.base_address = server["staticip"]["base_address"]
                    vm.base_mac     = server["staticip"]["base_mac"]
                end

                # Handle disk configuration
                # Initialize a disk number counter, loop through defined disks,
                # create the disk if it doesn't exist, and add it to the VM configuration.
                if server.key?("disks")
                    disk_number = 1
                    server["disks"].each do |disk|
                        # If a clone directory is provided, set the target path
                        # for additional disks to the clone directory, otherwise
                        # create the disk in the extra-disks directory in this
                        # project.
                        if vars['provider']&.[]('vmware')&.[]('clone_directory') 
                            extra_disk_dir  = File.join(vars['provider']['vmware']['clone_directory'], server['name'])
                        else
                            current_dir     = File.expand_path(File.dirname(__FILE__))
                            extra_disk_dir  = File.join(current_dir, "extra-disks/#{server['name']}")
                        end
                        
                        unless File.directory?(extra_disk_dir)
                            Dir.mkdir(extra_disk_dir)
                        end

                        extra_disk_path = "#{extra_disk_dir}/#{disk['name']}.vmdk".gsub('/', '\\')
                
                        unless File.exists?(extra_disk_path)
                            system("#{vdiskmgr_path} -c -s #{disk['size']}GB -t 0 \"#{extra_disk_path}\"")
                        end
                
                        # Add disk to VM configuration
                        vm.vmx["nvme0:#{disk_number}.fileName"] = extra_disk_path
                        vm.vmx["nvme0:#{disk_number}.present"] = "TRUE"
                        vm.vmx["nvme0:#{disk_number}.redo"] = ""
                
                        # Increment the disk number for the next disk
                        disk_number += 1            
                    end #end disks.each          
                end #end if server.key?("disks")

            end # end of srv.vm.provider "vmware_desktop"
            
            # Run default provisioning steps
            # set locale and timezone
            if vars.key?("locale")
                sys_tz = vars['locale']['timezone'] || 'Eastern Standard Time'
                sys_lc = vars['locale']['culture'] || 'en-US'
                srv.vm.provision "shell", path: "#{default_scripts}/configure-locale.ps1", privileged: true, args: "'#{sys_lc}', '#{sys_tz}'"
                srv.vm.provision "shell", reboot: true
            end

            # Initialize any Disks
            if server.key?("disks")
                srv.vm.provision "shell", path: "#{default_scripts}/initialize-disks.ps1", privileged: true
            end

            # Install Chocolatey
            srv.vm.provision "shell", path: "#{default_scripts}/install-choco.ps1", privileged: true, env: env
            srv.vm.provision "shell", path: "#{default_scripts}/configure-winserver.ps1", privileged: true, env: env
            srv.vm.provision "shell", reboot: true

            # Process any roles defined for the server, calling the appropriate Vagrantfile fragment
            # located in src/vagrant/Vagrantfile.<role>.rb
            if server.key?("roles") && server["roles"].is_a?(Array)
                server["roles"].each do |role|
                    role_file       = File.join(File.dirname(__FILE__), "vagrant/Vagrantfile.#{role}.rb")
                    role_scripts    = "src/roles/#{role}/scripts"
                    role_configs    = "src/roles/#{role}/configs"
                    eval(File.read(role_file), binding) if File.exist?(role_file)
                end
            end #end role processing

            srv.vm.provision "shell", path: "src/utils/export-ipinfo.ps1", privileged: false

        end # end of config.vm.define
    end # end of servers.each
end