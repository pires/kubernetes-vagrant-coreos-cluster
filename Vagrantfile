# -*- mode: ruby -*-
# vi: set ft=ruby :

required_plugins = %w(vagrant-triggers)
required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 1.6.0"

require 'fileutils'
require 'net/http'
require 'open-uri'

class Module
  def redefine_const(name, value)
    __send__(:remove_const, name) if const_defined?(name)
    const_set(name, value)
  end
end

MASTER_YAML = File.join(File.dirname(__FILE__), "master.yaml")
NODE_YAML = File.join(File.dirname(__FILE__), "node.yaml")

DOCKERCFG = File.expand_path(ENV['DOCKERCFG'] || "~/.dockercfg")

KUBERNETES_VERSION = ENV['KUBERNETES_VERSION'] || '0.11.0'
if KUBERNETES_VERSION == "latest"
  url = "https://get.k8s.io"
  Object.redefine_const(:KUBERNETES_VERSION,
    open(url).read().scan(/release=.*/)[0].gsub('release=v', ''))
end

CHANNEL = ENV['CHANNEL'] || 'alpha'
if CHANNEL != 'alpha'
  puts "============================================================================="
  puts "As this is a fastly evolving technology CoreOS' alpha channel is the only one"
  puts "expected to behave reliably. While one can invoke the beta or stable channels"
  puts "please be aware that your mileage may vary a whole lot."
  puts "So, before submitting a bug, in this project, or upstreams (either kubernetes"
  puts "or CoreOS) please make sure it (also) happens in the (default) alpha channel."
  puts "============================================================================="
end

COREOS_VERSION = ENV['COREOS_VERSION'] || 'latest'
upstream = "http://#{CHANNEL}.release.core-os.net/amd64-usr/current"
if COREOS_VERSION == "latest"
  url = "#{upstream}/version.txt"
  Object.redefine_const(:COREOS_VERSION,
    open(url).read().scan(/COREOS_VERSION=.*/)[0].gsub('COREOS_VERSION=', ''))
end

MVN_SYNC_FOLDER = ENV['MVN_SYNC_FOLDER'] || nil

NUM_INSTANCES = ENV['NUM_INSTANCES'] || 2

MASTER_MEM = ENV['MASTER_MEM'] || 512
MASTER_CPUS = ENV['MASTER_CPUS'] || 1

NODE_MEM= ENV['NODE_MEM'] || 1024
NODE_CPUS = ENV['NODE_CPUS'] || 1

SERIAL_LOGGING = (ENV['SERIAL_LOGGING'].to_s.downcase == 'true')
GUI = (ENV['GUI'].to_s.downcase == 'true')

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # always use Vagrants' insecure key
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  config.vm.box = "coreos-#{CHANNEL}"
  config.vm.box_version = ">= #{COREOS_VERSION}"
  config.vm.box_url = "#{upstream}/coreos_production_vagrant.json"

  # Configure maven repository to use host folder
  if MVN_SYNC_FOLDER != nil then
    config.vm.synced_folder "#{MVN_SYNC_FOLDER}", "/home/core/.m2/repository", :nfs => true, :mount_options => ['nolock,vers=3,udp,noatime']    
  end

  ["vmware_fusion", "vmware_workstation"].each do |vmware|
    config.vm.provider vmware do |v, override|
      override.vm.box_url = "#{upstream}/coreos_production_vagrant_vmware_fusion.json"
    end
  end

  config.vm.provider :parallels do |vb, override|
    override.vm.box = "AntonioMeireles/coreos-#{CHANNEL}"
    override.vm.box_url = "https://vagrantcloud.com/AntonioMeireles/coreos-#{CHANNEL}"
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

  (1..(NUM_INSTANCES.to_i + 1)).each do |i|
    if i == 1
      hostname = "master"
      cfg = MASTER_YAML
      memory = MASTER_MEM
      cpus = MASTER_CPUS
    else
      hostname = "node-%02d" % (i - 1)
      cfg = NODE_YAML
      memory = NODE_MEM
      cpus = NODE_CPUS
    end

    config.vm.define vmName = hostname do |kHost|
      kHost.vm.hostname = vmName

      if SERIAL_LOGGING
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "#{vmName}-serial.txt")
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
          v.customize("post-import",
            ["set", :id, "--device-add", "serial", "--output", serialFile])
          v.customize("pre-boot",
            ["set", :id, "--device-set", "serial0", "--output", serialFile])
        end
      end

      ["vmware_fusion", "vmware_workstation", "virtualbox"].each do |h|
        kHost.vm.provider h do |vb|
          vb.gui = GUI
        end
      end
      ["parallels", "virtualbox"].each do |h|
        kHost.vm.provider h do |n|
          n.memory = memory
          n.cpus = cpus
        end
      end

      kHost.vm.network :private_network, ip: "172.17.8.#{i+100}"
      # Uncomment below to enable NFS for sharing the host machine into the=
      # coreos-vagrant VM.
      # config.vm.synced_folder ".", "/home/core/share", id: "core",
      #   :nfs => true, :mount_options => ['nolock,vers=3,udp']
      kHost.vm.synced_folder ".", "/vagrant", disabled: true

      if File.exist?(DOCKERCFG)
        kHost.vm.provision :file, run: "always",
         :source => "#{DOCKERCFG}", :destination => "/home/core/.dockercfg"

        kHost.vm.provision :shell, run: "always" do |s|
          s.inline = "cp /home/core/.dockercfg /.dockercfg"
          s.privileged = true
        end
      end

      if File.exist?(cfg)
        kHost.vm.provision :file, :source => "#{cfg}", :destination => "/tmp/vagrantfile-user-data"
        kHost.vm.provision :shell, :privileged => true,
        inline: <<-EOF
          sed -i "s,__RELEASE__,v#{KUBERNETES_VERSION},g" /tmp/vagrantfile-user-data
          sed -i "s,__CHANNEL__,v#{CHANNEL},g" /tmp/vagrantfile-user-data
          mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
        EOF
      end
    end
  end
  config.trigger.after [:up, :resume] do
    info "making sure ssh agent has the default vagrant key..."
    system "ssh-add ~/.vagrant.d/insecure_private_key"
  end
end
