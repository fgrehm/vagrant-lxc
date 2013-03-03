# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box     = "quantal64"
  config.vm.box_url = "https://github.com/downloads/roderik/VagrantQuantal64Box/quantal64.box"

  config.vm.network :hostonly, "192.168.33.10"
  config.vm.forward_port 80, 8080
  config.vm.forward_port 2222, 2223

  config.vm.customize [
                    "modifyvm", :id,
                    "--memory", 1024,
                    "--cpus",   "2"
                  ]

  config.vm.share_folder("v-root", "/vagrant", ".", :nfs => true)
end
