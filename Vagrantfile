Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-7.5"

  config.vm.network "forwarded_port", guest: 8080, host: 8080

  config.vm.provider "virtualbox" do |vb|
    vb.name = "openmbee_mms"
    vb.cpus = 4
    vb.gui = false
    vb.memory = 12288
  end

end