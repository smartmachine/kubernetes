# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">= 1.6.0"

# Make sure the vagrant-ignition plugin is installed
required_plugins = %w(vagrant-ignition)

plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
if not plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  if system "vagrant plugin install #{plugins_to_install.join(' ')}"
    exec "vagrant #{ARGV.join(' ')}"
  else
    abort "Installation of one or more plugins has failed. Aborting."
  end
end

CONFIG = File.join(File.dirname(__FILE__), "config/config.rb")
if File.exist?(CONFIG)
  require CONFIG
else
  puts "It doesn't seem like you have configured this project yet!\n\n"
  puts "You have to do the following to get going:"
  puts "  1. Copy config/config.rb.in to config/config.rb and edit to taste."
  puts "  2. Run bin/generate.sh to generate bootkube assets and matchbox certificates."
  puts "  3. Add the following to your dnsmasq configuration (strongly recommended!):"
  puts "       address=/admin/192.168.99.3"
  puts "       address=/web/192.168.99.3"
  puts "       server=/kube.com/192.168.99.2"
  puts "       server=/99.168.192.in-addr.arpa/192.168.99.2\n\n"
  puts "Good luck!"
  exit! 
end

IGNITION_CONFIG_PATH = File.join(File.dirname(__FILE__), "config/ignition.json")

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.ssh.forward_agent = true
  config.ssh.private_key_path = [$vm_private_key]

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
    config.vm.box_url = "https://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant_virtualbox.json" % [$update_channel, $image_version]

    config.ignition.enabled = true 
    config.vm.hostname = vm_name
    config.vm.network :private_network, ip: "192.168.99.2"

    config.vm.provider :virtualbox do |vb|
      vb.gui = $vm_gui
      vb.memory = $matchbox_memory
      vb.cpus = $vm_cpus
      vb.customize ["modifyvm", :id, "--cpuexecutioncap", "#{$vb_cpuexecutioncap}"]
      config.ignition.config_obj = vb
      config.ignition.hostname = vm_name + ".kube.com"
      config.ignition.drive_root = "config/ignition"
      config.ignition.ip = "192.168.99.2"
      config.ignition.path = "../ignition.json"
    end

    config.vm.provision :file, :source => "provision/dnsmasq.service", :destination => "/tmp/dnsmasq.service"
    config.vm.provision :file, :source => "provision/matchbox.service", :destination => "/tmp/matchbox.service"
    config.vm.provision :file, :source => "provision/get-coreos", :destination => "/tmp/get-coreos"
    config.vm.provision :file, :source => "config/matchbox", :destination => "/home/core/matchbox"
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

      # Serial logging
      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % client)
        FileUtils.touch(serialFile)
      end

      pxe_client.vm.provider :virtualbox do |vb|
        vb.gui = $vm_gui
        if client =~ /master/ then
          vb.memory = $master_memory
        elsif client =~ /node/ then
          vb.memory = $node_memory
        else
          vb.memory = 2048
        end
        vb.cpus = $vm_cpus
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        if $enable_serial_logging
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end

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
        pxe_client.vm.provision :file, :source => "config/bootkube", :destination => "/home/core/bootkube"
        pxe_client.vm.provision :shell, :path => "provision/nodes.sh", :privileged => true
      end

    end
  end

end
