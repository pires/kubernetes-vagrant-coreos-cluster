# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">= 1.6.0"

MASTER_YAML = File.join(File.dirname(__FILE__), "master.yaml")
NODE_YAML = File.join(File.dirname(__FILE__), "node.yaml")

# Defaults for config options defined in CONFIG
$num_node_instances = 3
$update_channel = "alpha"
$enable_serial_logging = false
$vb_gui = false
$vb_master_memory = 512
$vb_master_cpus = 1
$vb_node_memory = 1024
$vb_node_cpus = 1

# Attempt to apply the deprecated environment variable NUM_INSTANCES to
# $num_node_instances while allowing config.rb to override it
if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
  $num_node_instances = ENV["NUM_INSTANCES"].to_i
end

Vagrant.configure("2") do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false

  config.vm.box = "coreos-%s" % $update_channel
  config.vm.box_version = ">= 591.0.0"
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % $update_channel

  config.vm.provider :vmware_fusion do |vb, override|
    override.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant_vmware_fusion.json" % $update_channel
  end

  config.vm.provider :parallels do |vb, override|
    override.vm.box = 'AntonioMeireles/coreos-%s' % $update_channel
    override.vm.box_url = 'https://vagrantcloud.com/AntonioMeireles/coreos-%s' % $update_channel
  end

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end
  config.vm.provider :parallels do |p|
    p.update_guest_tools = false
    p.check_guest_tools = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (1..$num_node_instances+1).each do |i|
    if i == 1
      hostname = "master"
      cfg = MASTER_YAML
      memory = $vb_master_memory
      cpus = $vb_master_cpus
    else
      hostname = "node-%02d" % (i - 1)
      cfg = NODE_YAML
      memory = $vb_node_memory
      cpus = $vb_node_cpus
    end

    config.vm.define vmName = hostname do |kHost|
      kHost.vm.hostname = vmName

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vmName)
        FileUtils.touch(serialFile)

        kHost.vm.provider :vmware_fusion do |v, override|
          v.vmx["serial0.present"] = "TRUE"
          v.vmx["serial0.fileType"] = "file"
          v.vmx["serial0.fileName"] = serialFile
          v.vmx["serial0.tryNoRxLoss"] = "FALSE"
        end
        kHost.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
        # supported since vagrant-parallels 1.3.7
        # https://github.com/Parallels/vagrant-parallels/issues/164
        kHost.vm.provider :parallels do |v|
          v.customize("post-import", ["set", :id, "--device-add", "serial", "--output", serialFile])
          v.customize("pre-boot", ["set", :id, "--device-set", "serial0", "--output", serialFile])
        end
      end

      ["vmware_fusion", "virtualbox"].each do |h|
        kHost.vm.provider h do |vb|
          vb.gui = $vb_gui
        end
      end
      ["parallels", "virtualbox"].each do |h|
        kHost.vm.provider h do |n|
          n.memory = memory
          n.cpus = cpus
        end
      end

      kHost.vm.network :private_network, ip: "172.17.8.#{i+100}"
      # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
      #config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      kHost.vm.synced_folder ".", "/vagrant", disabled: true

      if File.exist?(cfg)
        kHost.vm.provision :file, :source => "#{cfg}", :destination => "/tmp/vagrantfile-user-data"
        kHost.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end
    end
  end
end

