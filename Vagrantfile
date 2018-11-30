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

  config.vm.post_up_message = "OpenMBEE MMS Virtual Machine has been successfully created.

    Login to View Editor:
    ---------------------
    You can login to the View Editor by going to:

    http://localhost:8080/alfresco/mmsapp/mms.html#/login

    and using 'admin' as both the username and the password.

    Troubleshoot:
    -------------
    If that URL is missing, make sure Alfresco is running, by going to:

    http://localhost:8080/alfresco

    Important Notice:
    -----------------
    For this server to be useful, you will need to have: MagicDraw, the MDK plugin, and a model.

    As of Nov 30, 2018, the MDK plugin version for MagicDraw is 3.3.6 and can be found here:

    https://bintray.com/openmbee/maven/mdk/3.3.6

  "

end