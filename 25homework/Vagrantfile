# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :server => {
	:box_name => "centos/7",
	:forwarded_port => [
            {guest: 1195, host: 1195}
        ],
	:net => [
	    {ip: '192.168.10.100', adapter: 2, netmask: "255.255.255.255", virtualbox__intnet: "intra_net"},
	]
  },

  :clientTap => {
	:box_name => "centos/7",
	:net => [
	    {ip: '172.29.1.10', adapter: 2, netmask: "255.255.255.255", virtualbox__intnet: "intra_net"},
	]
  },

  :clientTun => {
	:box_name => "centos/7",
	:net => [
	    {ip: '172.29.2.10', adapter: 2, netmask: "255.255.255.255", virtualbox__intnet: "intra_net"},
	]
  }

}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|

	box.vm.box = boxconfig[:box_name]
	box.vm.host_name = boxname.to_s

	if boxconfig.key?(:forwarded_port)
	    boxconfig[:forwarded_port].each do |fp|
		box.vm.network "forwarded_port", fp
	    end
	end

	boxconfig[:net].each do |ipconf|
	  box.vm.network "private_network", ipconf
	end

	if boxconfig.key?(:public)
	  box.vm.network "public_network", boxconfig[:public]
	end

	box.vm.provider :virtualbox do |vb|
	    vb.customize ["modifyvm", :id, "--memory", "256"]
	end

	box.vm.provision "shell", inline: <<-SHELL
	  mkdir -p ~root/.ssh
	  cp ~vagrant/.ssh/auth* ~root/.ssh
	SHELL

	box.vm.provision "ansible" do |ansible|
	    ansible.compatibility_mode = "2.0"
	    ansible.playbook = "provisioning/playbook.yml"
	    ansible.become = "true"
	end

    end

  end

end
