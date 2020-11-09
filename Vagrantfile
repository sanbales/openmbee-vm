Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-7.5"
  
  config.vm.define "OpenMBEE Server"
  #config.vm.disk :disk, size: "100GB", primary: true
  config.disksize.size = "100GB"

  config.vm.network "forwarded_port", guest: 8080, host: 8080    # MMS
  config.vm.network "forwarded_port", guest: 9200, host: 9200    # ElasticSearch
  config.vm.network "forwarded_port", guest: 5432, host: 5432    # Postgres
  config.vm.network "forwarded_port", guest: 5433, host: 5433    # Postgres Admin GUI
  config.vm.network "forwarded_port", guest: 1358, host: 1358    # ElasticSearch GUI, Dejavu 
  config.vm.network "forwarded_port", guest: 13030, host: 13030  # Fuseki
  config.vm.network "forwarded_port", guest: 8088, host: 8088    # Webprotege
  config.vm.network "forwarded_port", guest: 8090, host: 8090    # Webprotege
  config.vm.network "forwarded_port", guest: 27017, host: 27017  # Webprotege's MongoDB

  config.vm.provider "virtualbox" do |vb|
    vb.name = "OpenMBEE Server"
    vb.cpus = 4
    vb.memory = 12288  # Solr requires a lot of RAM
    vb.gui = false
    
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
  end

  config.vm.provision "shell", path: "provision.sh"

  config.vm.post_up_message = "OpenMBEE MMS Virtual Machine has been successfully created.

    Visit https://github.com/MJDiaz89/openmbee-vm/ to learn how to use it.

  "

end
