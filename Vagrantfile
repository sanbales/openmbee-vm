Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.5"
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  config.vm.provider "virtualbox" do |vb|
    vb.name = "OpenMBEE Server"
    vb.cpus = 4
    vb.memory = 12288  # Solr requires a LOT of RAM
    vb.gui = false
  end

  config.vm.provision "shell", path: "provision.sh"

  message = "OpenMBEE MMS Virtual Machine has been successfully created.

    Login to View Editor:
    ---------------------
    You can login to the View Editor by going to:

    http://localhost:8080/alfresco/mmsapp/mms.html#/login

    and using 'admin' as the username and password.

    Troubleshoot:
    -------------
    If that URL is missing, make sure Alfresco is running, by going to:

    http://localhost:8080/alfresco

    Important Notice:
    -----------------
    To be useful you probably want MagicDraw, the MDK plugin, and a model. Installing and using those
    items is out of scope here. The MDK plugin version for MagicDraw is 3.3.6 and can be found here:

    https://bintray.com/openmbee/maven/mdk/3.3.6

  config.vm.post_up_message = message
  "

end