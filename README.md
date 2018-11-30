# OpenMBEE Server Virtual Machine

## Installation

1. Install [Vagrant][vagrant].

1. Install [VirtualBox][virtualbox].

1. Clone this repository:
    ```
    git clone ssh://git@bitbucket.di2e.net:7999/cet/openmbee-vm.git
    ```

1. Provision the virtual machine:
    ```
    cd openmbee-vm
    vagrant up
    ```

[openmbee]: http://www.openmbee.org/ "OpenMBEE"
[vagrant]: https://www.vagrantup.com/downloads.html "Vagrant"
[virtualbox]: https://www.virtualbox.org/wiki/Downloads "VirtualBox"

## Note

This virtual machine was developed as a stop-gap solution until a proper
containerized version of the [OpenMBEE][openmbee] server can be developed.
