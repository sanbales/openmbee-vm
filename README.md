# OpenMBEE Server VM

A vagrant-based virtual machine server for setting up the [OpenMBEE Docker Image][docker-image].

> This virtual machine was developed to facilitate the installation of the OpenMBEE Model 
Management System (MMS).  It is intended to be a stop-gap solution until a containerized 
version of the [OpenMBEE][openmbee] [MMS][mms] server can be developed.

## Installation

1. Install [Vagrant][vagrant].

1. Install [VirtualBox][virtualbox].

1. Clone this repository:
    ```
    git clone https://github.com/sanbales/openmbee-vm.git
    ```

1. Provision the virtual machine:
    ```
    cd openmbee-vm
    vagrant up
    ```

[docker-image]: https://hub.docker.com/r/openmbeeguest/mms-repo/ "OpenMBEE Docker Image"
[mms]: https://github.com/Open-MBEE/mms "Model Management System"
[openmbee]: http://www.openmbee.org/ "OpenMBEE"
[vagrant]: https://www.vagrantup.com/downloads.html "Vagrant"
[virtualbox]: https://www.virtualbox.org/wiki/Downloads "VirtualBox"
