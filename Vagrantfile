# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

require 'yaml'

# Load the provision.yaml file
conf    = YAML.load_file(File.join(File.dirname(__FILE__), 'provision.yaml'))
servers = conf['servers']
vars    = conf['vars']
env     = conf['env']
vdiskmgr_path = '"C:\\Program Files (x86)\\VMware\\VMware Workstation\\vmware-vdiskmanager.exe"'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Assuming Vagrantfiles are named like 'Vagrantfile.role'
  vagrantfiles = Dir.glob(File.join(File.dirname(__FILE__), 'vagrant/*/Vagrantfile.*'))

  # Load each Vagrantfile found in the subdirectories
  vagrantfiles.each do |vagrantfile|
    if File.exists?(vagrantfile)
      load File.expand_path(vagrantfile)
    end
  end
  
  # Your main Vagrantfile configuration can go here
  # This might include global settings or overrides that apply to all VMs
end