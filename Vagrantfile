# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">= 1.6.0"

CONFIG = File.join(File.dirname(__FILE__), "config/config.rb")
if File.exist?(CONFIG)
  require CONFIG
end
CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "config/user-data")

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.ssh.forward_agent = true
  config.ssh.private_key_path = [$vm_private_key, "~/.vagrant.d/insecure_private_key"]

  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # Matchbox Server
  config.vm.define vm_name = "matchbox" do |config|
    config.vm.box = "coreos-%s" % $update_channel
    if $image_version != "current"
      config.vm.box_version = $image_version
    end
    config.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]

    config.vm.hostname = vm_name
    config.vm.network :private_network, ip: "192.168.99.2"
    config.vm.provider :virtualbox do |vb|
      vb.gui = $vm_gui
      vb.memory = $matchbox_memory
      vb.cpus = $vm_cpus
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "#{$vb_cpuexecutioncap}"]
    end
    config.vm.provision :file, :source => "provision/dnsmasq.service", :destination => "/tmp/dnsmasq.service"
    config.vm.provision :file, :source => "provision/matchbox.service", :destination => "/tmp/matchbox.service"
    config.vm.provision :file, :source => "provision/get-coreos", :destination => "/tmp/get-coreos"
    config.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
    config.vm.provision :file, :source => "config/matchbox", :destination => "/home/core"
    config.vm.provision :shell, :path => "provision/matchbox.sh", :privileged => true
  end

  $node_data.keys().each do |client|
    config.vm.define client do |pxe_client|

      #SSH Config
      pxe_client.ssh.username = "core"

      # Self-created empty box
      pxe_client.vm.box = "pxeboot"
      pxe_client.vm.box_url = "file://%s" % File.join(File.dirname(__FILE__), "box/pxeboot.box")
      pxe_client.vm.boot_timeout = 3600

      # Internal Network
      pxe_client.vm.network :private_network, type: "dhcp", auto_config: false

      # Switch off folder syncing
      pxe_client.vm.synced_folder '.', '/vagrant', disabled: true

      pxe_client.vm.provider :virtualbox do |vb|
        vb.gui = $vm_gui
        if client =~ /master/ then
          vb.memory = $master_memory
        elsif client =~ /node/ then
          vb.memory = $node_memory
        else
          vb.memory = 1024
        end
        vb.cpus = $vm_cpus
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
        vb.customize ["modifyvm", :id, "--audio", "none"]

        # PXE Booting Voodoo
        vb.customize [
          'modifyvm', :id,
          '--nictype2', '82540EM',
          '--nic2', 'hostonly',
          '--hostonlyadapter2', 'vboxnet0',
          '--boot1', 'disk',
          '--boot2', 'net',
          '--boot3', 'none',
          '--boot4', 'none',
          '--macaddress2', $node_data[client][:mac],
          '--nicbootprio2', '1'
        ]
      end

      if client =~ /master/ || client =~ /node/ then
        # Copy up bootkube config and move into place
        pxe_client.vm.provision :file, :source => "config/bootkube", :destination => "/home/core"
        pxe_client.vm.provision :shell, :path => "provision/nodes.sh", :privileged => true
      end

    end
  end

end
