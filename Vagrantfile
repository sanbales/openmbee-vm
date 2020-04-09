Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-7.5"
  
  config.vm.define "MMS VE Server 2"

  config.vm.network "forwarded_port", guest: 8080, host: 8080 #MMS
  config.vm.network "forwarded_port", guest: 9200, host: 9200 #ElasticSearch
  config.vm.network "forwarded_port", guest: 5432, host: 5432 #Postgres
  config.vm.network "forwarded_port", guest: 5433, host: 5433 #Postgres Admin GUI

  config.vm.provider "virtualbox" do |vb|
    vb.name = "MMS VE Server"
    vb.cpus = 4
    vb.memory = 12288  # Solr requires a lot of RAM
    vb.gui = false
  end

  config.vm.provision "shell", path: "provision.sh"

  config.vm.post_up_message = "OpenMBEE MMS Virtual Machine has been successfully created.

    Visit https://github.com/MJDiaz89/openmbee-vm/ to learn how to use it.

  "

end