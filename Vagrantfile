#!/usr/bin/env ruby

Vagrant::Config.run do |config|
  ssh_key = File.read(File.expand_path("~/.ssh/id_rsa.pub"))

  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/#{config.vm.box}.box"
  config.vm.network :hostonly, "192.168.6.66"

  config.vm.provision :shell, :inline => "test -d /etc/skel/.ssh || mkdir /etc/skel/.ssh"
  config.vm.provision :shell do |shell|
    shell.inline = "echo $@ | tee /etc/skel/.ssh/authorized_keys"
    shell.args = ssh_key
  end
  config.vm.provision :shell do |shell|
    shell.path = File.expand_path("../script/bootstrap.sh", __FILE__)
    shell.args = `whoami`.chomp
  end
  config.vm.provision :shell, :inline => "bash -lc 'rvm use --install --default ruby-1.9.3'"
  config.vm.provision :shell, :inline => "bash -lc 'gem install chef --no-rdoc --no-ri'"
end
