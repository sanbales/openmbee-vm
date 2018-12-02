# VM for OpenMBEE MMS

A vagrant-based virtual machine (VM) for setting up the [Open Model Based Engineering Environment (OpenMBEE)][openmbee]
[Model Management System (MMS)][mms].  This VM helps instantiate the [OpenMBEE MMS Docker Image][docker-image].

> This virtual machine was developed to facilitate the installation of the OpenMBEE MMS server.
It is intended as a stop-gap solution until a scalable containerized version of the OpenMBEE MMS
server can be developed, e.g., using [Kubernetes][kubernetes].

## Installation

1. Install [Vagrant][vagrant].

2. Install [VirtualBox][virtualbox].

3. Clone this repository:
    ```
    git clone https://github.com/sanbales/openmbee-vm.git
    ```

4. Provision the virtual machine:
    ```
    cd openmbee-vm
    vagrant up
    ```

> The first time you run this, it will take some time to start all the services, so please be patient.

## Usage

### Login to View Editor
You can login to the OpenMBEE [View Editor][view-editor] by going to:

    http://localhost:8080/alfresco/mmsapp/mms.html#/login

and using `admin` as both the username and the password.

### Troubleshoot
If that URL is not responding, make sure [Alfresco][alfresco] is running, by going to:

    http://localhost:8080/alfresco

If that is not working, checkout the `docker-compose` logs by:

1. SSH'ing into the VM:

    ```
    vagrant ssh
    ```

2. And inspecting the logs:

    ```
    docker-compose -f /vagrant/docker-compose.yml logs
    ```
    
    Alternatively, a user can use the `dc` alias command:
    
    ```
    dc logs
    ``` 
    
    For more information on the custom commands, type:
    
    ```
    commands
    ``` 

### Important Notice
For this server to be useful, you will need to have: [MagicDraw][magicdraw], the
[Model Development Kit (MDK)][mdk] plugin, and a SysML model.

As of Nov 30, 2018, the latest MDK plugin version for MagicDraw is 3.3.6 and can be found here:

    https://bintray.com/openmbee/maven/mdk/3.3.6

[alfresco]: https://www.alfresco.com/ "Alfresco"
[docker-image]: https://hub.docker.com/r/openmbeeguest/mms-repo/ "OpenMBEE Docker Image"
[kubernetes]: https://kubernetes.io/ "Kubernetes"
[magicdraw]: https://www.nomagic.com/products/magicdraw "MagicDraw"
[mdk]: https://github.com/Open-MBEE/mdk "Model Development Kit"
[mms]: https://github.com/Open-MBEE/mms "Model Management System"
[openmbee]: http://www.openmbee.org/ "OpenMBEE"
[vagrant]: https://www.vagrantup.com/downloads.html "Vagrant"
[view-editor]: https://github.com/Open-MBEE/ve "View Editor"
[virtualbox]: https://www.virtualbox.org/wiki/Downloads "VirtualBox"
