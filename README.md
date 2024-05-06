# Vagrant-Based Lab

This repository is essentially a set of scripts and configuration files that can be used to create a
virtual lab environment using Vagrant. The lab environment is controlled primarily through the
`Vagrantfile` and the `provision.yaml` files. Beyond that, this project stores Vagrantfile "snippets"
in the `vagrant` directory. These snippets are intended to be called from the main `Vagrantfile` based
on the roles defined in the `provision.yaml` file.

The provided `Vagrantfile` is designed to work with VMWare Workstation, but can be easily modified to
work with VirtualBox or other Vagrant providers.

Just running `vagrant up` after cloning this repository will create 2 virtual machines, a Windows Server
Domain controller and a Windows Server member server. The domain controller is configured with a domain
named `dev.local` and the member server is joined to that domain. 

Active Directory is pre-populated with users and groups based on the `src/roles/domain-controller/users.csv`
file. They all have the password `Foo_b_ar123!`.


## Vagrantfile breakdown

The `Vagrantfile` is the main configuration file for the Vagrant environment. It is responsible for
defining the virtual machines that will be created, as well as the configuration of those virtual
machines. The `Vagrantfile` in this repository is broken down into several sections:

## Headers/Includes

The first part of the `Vagrantfile` is the headers and includes. This section is responsible for
loading the necessary ruby plugins, as well as loading the `provision.yaml` file and defining the
variables that are used throughout the rest of the `Vagrantfile`.


### VM Configuration Section

Line 14 `servers.each do |server|` starts the virtual machine configuration block. This block loops
through all the servers defined in `provision.yaml` and creates a virtual machine for each one.

### VMWare Workstation Section

Line 26 `srv.vm.provider "vmware_desktop" do |vm|` starts the VMWare Workstation provider configuration
where things like the number of CPUs, amount of memory, and the clone directory are defined. This is
also where extra disks are created and attached to the virtual machines.

## provision.yaml breakdown

All of the configuration for the virtual machines is stored in the `provision.yaml` file. This file
is a YAML file that defines the roles that each virtual machine will have, as well as the configuration
for each role. The `provision.yaml` file is broken down into several sections:


### vars

This block is intended to be used to define variables that can be used in the `Vagrantfile` and the
role-specific configuration files. These variables can be used to define variables to be passed to
scripts, or to control the behavior of the Vagrant environment. The included `provision.yaml` file
defines a few variables that are used to control the behavior of the Vagrant environment, such as the
culture and timezone of the virtual machines, as well as setting the clone directory for the VMWare
Workstation provider.

This is a fairly flexible block, and can be used to define any variables that are needed for the
provisioning process. The example below illustrates how the `clone_directory` variable is defined
in the provided `provision.yaml` file, and then how it is used in the `Vagrantfile`:

In `provision.yaml`:

```yaml
vars:
  provider:
    vmware:
      clone_directory: "C:\\VMs"
```

In the `Vagrantfile`, the `clone_directory` variable is accessed like this:

```rb
    srv.vm.provider "vmware_desktop" do |vm|
        vm.vmx["cpuid.coresPerSocket"]  = "1"
        vm.vmx["memsize"]               = server['memory'] || "1024"
        vm.vmx["numvcpus"]              = server['cpus'] || "2"
        vm.gui = true

        if vars['provider']&.[]('vmware')&.[]('clone_directory')
          vm.clone_directory = "#{vars['provider']['vmware']['clone_directory']}\\#{server['name']}"
        end
    ...
```


### env

This block is intended to be used to define environment variables that can be passed to the Vagrant
shell provisioner. When passed this way, these varibles are available at runtime in the shell scripts
that are executed by the provisioner. 

To access those in a PowerShell script:

```yaml
env:
  MY_ENV_VAR: "my value"
```

```powershell
$env:MY_ENV_VAR
```


### servers

This block is where all virtual machines are defined, not just servers. Each block in the `servers`
section defines a virtual machine that will be created by Vagrant, and must have the following
2 keys at a bare minimum:

1. `name` - The name of the virtual machine. This is used to identify the virtual machine in the
   Vagrant environment.
2. `box` - The box that will be used to create the virtual machine. This can be a local box, or a
   box from Vagrant Cloud.

### roles

The `roles` block is where the roles for each virtual machine are defined. Each role is defined as
an array item in the `roles` block. The name of the role is mapped to a Vagrantfile snippet, and is
used to calculate the path to role-specific configuration files and scripts.


## Adding a new role

Support for additional roles is easy to add. Simply create a new Vagrantfile snippet in the `vagrant`
directory with the name `Vagrantfile.<role>.rb`, and add the role to the `provision.yaml` file in a
server block. The role will be automatically applied to the virtual machine when it is created.

If a role requires additional configuration, create a directory in the `roles` directory with the
name of the role, and add the necessary configuration files to that directory.

Role scripts should be placed in the `src/roles/<role>/scripts` directory, and role-specific configuration
files should be placed in the `src/roles/<role>/config` directory.

The following variables are available to the role-specific configuration files:

1. `server` - The server block from the `provision.yaml` file.
2. `default_scripts` - The path to the `default_scripts` directory.
3. `role_scripts` - The path to the role-specific scripts directory.
4. `role_config` - The path to the role-specific configuration files directory.
5. `role_file` - The path to the role-specific Vagrantfile snippet.
6. `utils_scripts` - The path to the `utils` directory.
7. `env` - The environment variables defined in the `provision.yaml` file.
8. `vars` - The variables defined in the `provision.yaml` file.