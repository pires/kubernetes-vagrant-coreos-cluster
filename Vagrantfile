# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
require 'net/http'
require 'open-uri'

Vagrant.require_version ">= 1.6.0"

MASTER_YAML = File.join(File.dirname(__FILE__), "master.yaml")
NODE_YAML = File.join(File.dirname(__FILE__), "node.yaml")

$num_node_instances = ENV['NUM_INSTANCES'] || 2
$update_channel = ENV['CHANNEL'] || 'alpha'
$coreos_version = ENV['COREOS_VERSION'] || 'latest'
$enable_serial_logging = (ENV['SERIAL_LOGGING'].to_s.downcase == 'true')
$vb_gui = (ENV['GUI'].to_s.downcase == 'true')
$vb_master_memory = ENV['MASTER_MEM'] || 512
$vb_master_cpus = ENV['MASTER_CPUS'] || 1
$vb_node_memory = ENV['NODE_MEM'] || 1024
$vb_node_cpus = ENV['NODE_CPUS'] || 1
$kubernetes_version = ENV['KUBERNETES_VERSION'] || '0.9.3'

if $update_channel != 'alpha'
	puts "============================================================================="
	puts "As this is a fastly evolving technology CoreOS' alpha channel is the only one"
	puts "expected to behave reliably. While one can invoke the beta or stable channels"
	puts "please be aware that your mileage may vary a whole lot."
	puts "So, before submitting a bug, in this project, or upstream  (either kubernetes"
	puts "or CoreOS) please make sure it (also) happens in the (default) alpha channel."
	puts "============================================================================="
end

if $coreos_version == "latest"
  url = "http://#{$update_channel}.release.core-os.net/amd64-usr/current/version.txt"
  $coreos_version = open(url).read().scan(/COREOS_VERSION=.*/)[0].gsub('COREOS_VERSION=', '')
end

if $kubernetes_version == "latest"
  url = "https://get.k8s.io"
  $kubernetes_version = open(url).read().scan(/release=.*/)[0].gsub('release=v', '')
end

Vagrant.configure("2") do |config|
  # always use Vagrants' insecure key
  config.ssh.insert_key = false

  config.vm.box = "coreos-%s" % $update_channel
  config.vm.box_version = ">= #{$coreos_version}"
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % $update_channel

  ["vmware_fusion", "vmware_workstation"].each do |vmware|
    config.vm.provider vmware do |v, override|
      override.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant_vmware_fusion.json" % $update_channel
    end
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

  (1..($num_node_instances.to_i + 1)).each do |i|
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

        ["vmware_fusion", "vmware_workstation"].each do |vmware|
          kHost.vm.provider vmware do |v, override|
            v.vmx["serial0.present"] = "TRUE"
            v.vmx["serial0.fileType"] = "file"
            v.vmx["serial0.fileName"] = serialFile
            v.vmx["serial0.tryNoRxLoss"] = "FALSE"
          end
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

      ["vmware_fusion", "vmware_workstation", "virtualbox"].each do |h|
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
        kHost.vm.provision :shell, :privileged => true,
        inline: <<-EOF
          sed -i 's,__RELEASE__,v#{$kubernetes_version},g' /tmp/vagrantfile-user-data
          mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
        EOF
      end
    end
  end
end

