# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
require 'net/http'
require 'open-uri'
require 'json'

class Module
  def redefine_const(name, value)
    __send__(:remove_const, name) if const_defined?(name)
    const_set(name, value)
  end
end

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
   (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

required_plugins = %w(vagrant-triggers)

# check either 'http_proxy' or 'HTTP_PROXY' environment variable
enable_proxy = !(ENV['HTTP_PROXY'] || ENV['http_proxy'] || '').empty?
if enable_proxy
  required_plugins.push('vagrant-proxyconf')
end

if OS.windows?
  required_plugins.push('vagrant-winnfsd')
end

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

MASTER_YAML = File.join(File.dirname(__FILE__), "master.yaml")
NODE_YAML = File.join(File.dirname(__FILE__), "node.yaml")

USE_DOCKERCFG = ENV['USE_DOCKERCFG'] || false
DOCKERCFG = File.expand_path(ENV['DOCKERCFG'] || "~/.dockercfg")

KUBERNETES_VERSION = ENV['KUBERNETES_VERSION'] || '0.17.0'

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
upstream = "http://#{CHANNEL}.release.core-os.net/amd64-usr/#{COREOS_VERSION}"
if COREOS_VERSION == "latest"
  upstream = "http://#{CHANNEL}.release.core-os.net/amd64-usr/current"
  url = "#{upstream}/version.txt"
  Object.redefine_const(:COREOS_VERSION,
    open(url).read().scan(/COREOS_VERSION=.*/)[0].gsub('COREOS_VERSION=', ''))
end

NUM_INSTANCES = ENV['NUM_INSTANCES'] || 2

MASTER_MEM = ENV['MASTER_MEM'] || 512
MASTER_CPUS = ENV['MASTER_CPUS'] || 1

NODE_MEM= ENV['NODE_MEM'] || 1024
NODE_CPUS = ENV['NODE_CPUS'] || 1

BASE_IP_ADDR = ENV['BASE_IP_ADDR'] || "172.17.8"

DNS_DOMAIN = ENV['DNS_DOMAIN'] || "kubernetes.local"
DNS_UPSTREAM_SERVERS = ENV['DNS_UPSTREAM_SERVERS'] || "8.8.8.8:53,8.8.4.4:53"

SERIAL_LOGGING = (ENV['SERIAL_LOGGING'].to_s.downcase == 'true')
GUI = (ENV['GUI'].to_s.downcase == 'true')

if enable_proxy
  HTTP_PROXY = ENV['HTTP_PROXY'] || ENV['http_proxy']
  HTTPS_PROXY = ENV['HTTPS_PROXY'] || ENV['https_proxy']
  NO_PROXY = ENV['NO_PROXY'] || ENV['no_proxy'] || "localhost"
end

REMOVE_VAGRANTFILE_USER_DATA_BEFORE_HALT = (ENV['REMOVE_VAGRANTFILE_USER_DATA_BEFORE_HALT'].to_s.downcase == 'true')
# if this is set true, remember to use --provision when executing vagrant up / reload

CLOUD_PROVIDER = ENV['CLOUD_PROVIDER'].to_s.downcase || 'vagrant'
validCloudProviders = [ 'gce', 'gke', 'aws', 'azure', 'vagrant', 'vsphere',
  'libvirt-coreos', 'juju' ]
Object.redefine_const(:CLOUD_PROVIDER,
  'vagrant') unless validCloudProviders.include?(CLOUD_PROVIDER)

(1..(NUM_INSTANCES.to_i + 1)).each do |i|
  case i
  when 1
    hostname = "master"
    ETCD_SEED_CLUSTER = "#{hostname}=http://#{BASE_IP_ADDR}.#{i+100}:2380"
  else
    hostname = ",node-%02d" % (i - 1)
  end
end

# Read YAML file with mountpoint details
MOUNT_POINTS = YAML::load_file('synced_folders.yaml')

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # always use Vagrants' insecure key
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  config.vm.box = "coreos-#{CHANNEL}"
  config.vm.box_version = ">= #{COREOS_VERSION}"
  config.vm.box_url = "#{upstream}/coreos_production_vagrant.json"

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

  # setup VM proxy to system proxy environment
  if Vagrant.has_plugin?("vagrant-proxyconf") && enable_proxy
    config.proxy.http = HTTP_PROXY
    config.proxy.https = HTTPS_PROXY
    # most http tools, like wget and curl do not undestand IP range
    # thus adding each node one by one to no_proxy
    (1..(NUM_INSTANCES.to_i + 1)).each do |i|
      Object.redefine_const(:NO_PROXY, "#{NO_PROXY},#{BASE_IP_ADDR}.#{i+100}")
    end
    config.proxy.no_proxy = NO_PROXY
    # proxyconf plugin use wrong approach to set Docker proxy for CoreOS
    # force proxyconf to skip Docker proxy setup
    config.proxy.enabled = { docker: false }
  end

  (1..(NUM_INSTANCES.to_i + 1)).each do |i|
    if i == 1
      hostname = "master"
      cfg = MASTER_YAML
      memory = MASTER_MEM
      cpus = MASTER_CPUS
      MASTER_IP="#{BASE_IP_ADDR}.#{i+100}"
    else
      hostname = "node-%02d" % (i - 1)
      cfg = NODE_YAML
      memory = NODE_MEM
      cpus = NODE_CPUS
    end

    config.vm.define vmName = hostname do |kHost|
      kHost.vm.hostname = vmName
      # vagrant-triggers has no concept of global triggers so to avoid having
      # then to run as many times as the total number of VMs we only call them
      # in the master (re: emyl/vagrant-triggers#13)...
      if vmName == "master"
        kHost.trigger.before [:up, :provision] do
          info "Setting Kubernetes version #{KUBERNETES_VERSION}"
          sedInplaceArg = OS.mac? ? " ''" : ""
          system "cp setup.tmpl temp/setup"
          system "sed -e 's|__KUBERNETES_VERSION__|#{KUBERNETES_VERSION}|g' -i#{sedInplaceArg} ./temp/setup"
          system "sed -e 's|__MASTER_IP__|#{MASTER_IP}|g' -i#{sedInplaceArg} ./temp/setup"
          if enable_proxy
            system "sed -e 's|__PROXY_LINE__||g' -i#{sedInplaceArg} ./temp/setup"
            system "sed -e 's|__NO_PROXY__|#{NO_PROXY}|g' -i#{sedInplaceArg} ./temp/setup"
          else
            system "sed -e '/__PROXY_LINE__/d' -i#{sedInplaceArg} ./temp/setup"
          end
          system "chmod +x temp/setup"

          info "Configuring Kubernetes cluster DNS..."
          system "cp dns/dns-controller.yaml.tmpl temp/dns-controller.yaml"
          system "sed -e 's|__MASTER_IP__|#{MASTER_IP}|g' -i#{sedInplaceArg} ./temp/dns-controller.yaml"
          system "sed -e 's|__DNS_DOMAIN__|#{DNS_DOMAIN}|g' -i#{sedInplaceArg} ./temp/dns-controller.yaml"
          system "sed -e 's|__DNS_UPSTREAM_SERVERS__|#{DNS_UPSTREAM_SERVERS}|g' -i#{sedInplaceArg} ./temp/dns-controller.yaml"
        end

        if OS.windows?
          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "temp/setup"), :destination => "/home/core/kubectlsetup"
          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "temp/dns-controller.yaml"), :destination => "/home/core/dns-controller.yaml"
          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "dns/dns-service.yaml"), :destination => "/home/core/dns-service.yaml"
        end

        kHost.trigger.after [:up, :resume] do
          info "Sanitizing stuff..."
          system "ssh-add ~/.vagrant.d/insecure_private_key"
          system "rm -rf ~/.fleetctl/known_hosts"
        end

        kHost.trigger.after [:up] do
          info "Installing kubectl for the kubernetes version we just bootstrapped..."
          if OS.windows?
            run_remote "sudo -u core /bin/sh /home/core/kubectlsetup install"
          else
            system "./temp/setup install"
          end

          info "Waiting for Kubernetes master to become ready..."
          j, uri, res = 0, URI("http://#{MASTER_IP}:8080"), nil
          loop do
            j += 1
            begin
              res = Net::HTTP.get_response(uri)
            rescue
              sleep 10
            end
            break if res.is_a? Net::HTTPSuccess or j >= 50
          end

          res, uri.path = nil, '/api/v1beta1/replicationControllers/kube-dns'
          begin
            res = Net::HTTP.get_response(uri)
          rescue
          end
          if not res.is_a? Net::HTTPSuccess
            if OS.windows?
              run_remote "/opt/bin/kubectl create -f /home/core/dns-controller.yaml"
            else
              system "kubectl create -f temp/dns-controller.yaml"
            end
          end

          res, uri.path = nil, '/api/v1beta1/services/kube-dns'
          begin
            res = Net::HTTP.get_response(uri)
          rescue
          end
          if not res.is_a? Net::HTTPSuccess
            if OS.windows?
              run_remote "/opt/bin/kubectl create -f /home/core/dns-service.yaml"
            else
              system "kubectl create -f dns/dns-service.yaml"
            end
          end

        end
      end

      if vmName == "node-%02d" % (i - 1)
        kHost.trigger.after [:up] do
          info "Waiting for Kubernetes minion [node-%02d" % (i - 1) + "] to become ready..."
          j, uri, hasResponse = 0, URI("http://#{BASE_IP_ADDR}.#{i+100}:10250"), false
          loop do
            j += 1
            begin
              res = Net::HTTP.get_response(uri)
              hasResponse = true
            rescue Net::HTTPBadResponse
              hasResponse = true
            rescue
              sleep 10
            end
            break if hasResponse or j >= 50
          end
        end
      end

      kHost.trigger.before [:halt, :reload] do
        if REMOVE_VAGRANTFILE_USER_DATA_BEFORE_HALT
          run_remote "sudo rm -f /var/lib/coreos-vagrant/vagrantfile-user-data"
        end
      end

      kHost.trigger.before [:destroy] do
        system <<-EOT.prepend("\n\n") + "\n"
          rm -f temp/*
        EOT
      end

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

      kHost.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{i+100}"
      # you can override this in synced_folders.yaml
      kHost.vm.synced_folder ".", "/vagrant", disabled: true

      begin
        MOUNT_POINTS.each do |mount|
          mount_options = ""
          disabled = false
          nfs =  true
          if mount['mount_options']
            mount_options = mount['mount_options']
          end
          if mount['disabled']
            disabled = mount['disabled']
          end
          if mount['nfs']
            nfs = mount['nfs']
          end
          if File.exist?(File.expand_path("#{mount['source']}"))
            if mount['destination']
              kHost.vm.synced_folder "#{mount['source']}", "#{mount['destination']}",
                id: "#{mount['name']}",
                disabled: disabled,
                mount_options: ["#{mount_options}"],
                nfs: nfs
            end
          end
        end
      rescue
      end

      if USE_DOCKERCFG && File.exist?(DOCKERCFG)
        kHost.vm.provision :file, run: "always",
         :source => "#{DOCKERCFG}", :destination => "/home/core/.dockercfg"

        kHost.vm.provision :shell, run: "always" do |s|
          s.inline = "cp /home/core/.dockercfg /root/.dockercfg"
          s.privileged = true
        end
      end

      if File.exist?(cfg)
        kHost.vm.provision :file, :source => "#{cfg}", :destination => "/tmp/vagrantfile-user-data"
        if enable_proxy
          kHost.vm.provision :shell, :privileged => true,
          inline: <<-EOF
          sed -i "s|__PROXY_LINE__||g" /tmp/vagrantfile-user-data
          sed -i "s|__HTTP_PROXY__|#{HTTP_PROXY}|g" /tmp/vagrantfile-user-data
          sed -i "s|__HTTPS_PROXY__|#{HTTPS_PROXY}|g" /tmp/vagrantfile-user-data
          sed -i "s|__NO_PROXY__|#{NO_PROXY}|g" /tmp/vagrantfile-user-data
          EOF
        end
        kHost.vm.provision :shell, :privileged => true,
        inline: <<-EOF
          sed -i "/__PROXY_LINE__/d" /tmp/vagrantfile-user-data
          sed -i "s,__RELEASE__,v#{KUBERNETES_VERSION},g" /tmp/vagrantfile-user-data
          sed -i "s,__CHANNEL__,v#{CHANNEL},g" /tmp/vagrantfile-user-data
          sed -i "s,__NAME__,#{hostname},g" /tmp/vagrantfile-user-data
          sed -i "s,__CLOUDPROVIDER__,#{CLOUD_PROVIDER},g" /tmp/vagrantfile-user-data
          sed -i "s|__MASTER_IP__|#{MASTER_IP}|g" /tmp/vagrantfile-user-data
          sed -i "s|__DNS_DOMAIN__|#{DNS_DOMAIN}|g" /tmp/vagrantfile-user-data
          sed -i "s|__ETCD_SEED_CLUSTER__|#{ETCD_SEED_CLUSTER}|g" /tmp/vagrantfile-user-data
          sed -i "s|__NODE_CPUS__|#{NODE_CPUS}|g" /tmp/vagrantfile-user-data
          sed -i "s|__NODE_MEM__|#{NODE_MEM}|g" /tmp/vagrantfile-user-data
          mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
        EOF
      end
    end
  end
end
