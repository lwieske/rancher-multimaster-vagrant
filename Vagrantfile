# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'securerandom'

nodes = {
    # Name        CPU, RAM, NET
    'mgmt01'  => [  1,   1,  10 ],
    'ctrl01'  => [  1,   1, 101 ],
    'ctrl02'  => [  1,   1, 102 ],
    'ctrl03'  => [  1,   1, 103 ],
    'data01'  => [  2,   2, 201 ]
}

rancher_version = "v2.2.4-amd64"
#k8s_version     = 

admin_password  = SecureRandom.hex(8)

puts "Admin Username: " + "admin"
puts "Admin Password: " + String(admin_password)

pod_network_cidr      = '10.12.0.0/16'
service_cidr          = '10.13.0.0/16'  # default is 10.96.0.0/12
service_dns_domain    = 'vagrant.local' # default is cluster.local

PREFIXES=[ "10.10.10" ]

rancher_ip = "10.10.10.10"

$script = <<INLINE
#!/usr/bin/env bash

	curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl &>/dev/null

	chmod +x /usr/local/bin/kubectl

	case `hostname` in
		mgmt*)      
			/vagrant/configure-rancher.sh #{admin_password} #{rancher_version}
			;;
		ctrl* | data*)      
			/vagrant/configure-node.sh #{rancher_ip} #{admin_password}
			;;
		*)
			commands
			;;
	esac

INLINE

Vagrant.configure("2") do |config|

#	config.vm.box = ENV['VAGRANT_BOX'] || "centos-7.6-docker-18.09.6"
#	config.vm.box = "centos-7.6-docker-18.09.6"
#	config.vm.box = "centos/atomic-host"
	config.vm.box = "docker-18.09.7"

	nodes.each do |name, (cpu, ram, net, hdds)|

		hostname = "%s" % [name]

		config.hostmanager.enabled 			 = true
		config.hostmanager.manage_guest 	 = true
		config.hostmanager.ignore_private_ip = false

		config.vm.define "#{hostname}" do |box|

			box.vm.hostname = "#{hostname}.local"

			box.vm.network :private_network, ip: PREFIXES[0] + "." + net.to_s

			box.vm.provider :virtualbox do |vbox|
				vbox.customize ["modifyvm", :id, "--cpus",   cpu]
				vbox.customize ["modifyvm", :id, "--memory", ram * 1024]
			end

        	box.vm.provision :shell, :inline => $script

		end

    end

end