# -*- mode: ruby -*-
# vim: set ft=ruby :
home = ENV['HOME']
ENV["LC_ALL"] = "en_US.UTF-8"

MACHINES = {
  :R1 => {
        :box_name => "centos/7",
        :net => [
    		    {ip: '10.10.0.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "net-r1-r2"},
    		    {ip: '10.20.0.1', adapter: 3, netmask: "255.255.255.252", virtualbox__intnet: "net-r1-r3"},
    		    {ip: '10.40.0.1', adapter: 4, netmask: "255.255.255.0", virtualbox__intnet: "net-r1-out"}
    		]
  },
  :R2 => {
        :box_name => "centos/7",
        :net => [
		    {ip: '10.10.0.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "net-r1-r2"},
		    {ip: '10.30.0.1', adapter: 3, netmask: "255.255.255.252", virtualbox__intnet: "net-r2-r3"},
		    {ip: '10.50.0.1', adapter: 4, netmask: "255.255.255.0", virtualbox__intnet: "net-r2-out"}
    		]
  },
  :R3 => {
        :box_name => "centos/7",
        :net => [
		    {ip: '10.20.0.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "net-r1-r3"},
		    {ip: '10.30.0.2', adapter: 3, netmask: "255.255.255.252", virtualbox__intnet: "net-r2-r3"},
		    {ip: '10.60.0.1', adapter: 4, netmask: "255.255.255.0", virtualbox__intnet: "net-r3-out"}
    		]
  }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|

      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s

      boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
      end

      if boxconfig.key?(:public)
          box.vm.network "public_network", boxconfig[:public]
      end

      box.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "512"]
      end

      box.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
        sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
        systemctl restart sshd
        for i in /proc/sys/net/ipv4/conf/*/rp_filter ; do echo 0 > $i ; done
      SHELL

      box.vm.provision "ansible" do |ansible|
	  ansible.compatibility_mode = "2.0"
	  ansible.playbook = "playbooks/ospf.yml"
	  ansible.become = "true"
      end

    end
  end
end
