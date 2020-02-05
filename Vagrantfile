Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-7.5"

  config.vm.network "forwarded_port", guest: 8080, host: 8080

  config.vm.provider "virtualbox" do |vb|
    vb.name = "MMS Server"
    vb.cpus = 4
    vb.memory = 12288  # Solr requires a lot of RAM
    vb.gui = false
  end

  config.vm.provision "shell", path: "provision.sh"

  config.vm.post_up_message = "OpenMBEE MMS Virtual Machine has been successfully created.

    Visit https://github.com/MJDiaz89/openmbee-vm/ to learn how to use it.

  "

end