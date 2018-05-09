# -*- mode: ruby -*-
# vi: set ft=ruby :

require "fileutils"
require "net/http"
require "open-uri"
require "json"
require "date"
require "pathname"

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
enable_proxy = !(ENV["HTTP_PROXY"] || ENV["http_proxy"] || "").empty?
if enable_proxy
  required_plugins.push("vagrant-proxyconf")
end

if OS.windows?
  required_plugins.push("vagrant-winnfsd")
end

required_plugins.push("vagrant-timezone")

required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(" ")}" if need_restart
end

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2.1.1"

MASTER_YAML = File.join(File.dirname(__FILE__), "master.yaml")
NODE_YAML = File.join(File.dirname(__FILE__), "node.yaml")

# AUTHORIZATION MODE is a setting for enabling or disabling RBAC for your Kubernetes Cluster
# The default mode is ABAC.
AUTHORIZATION_MODE = ENV["AUTHORIZATION_MODE"] || "AlwaysAllow"

if AUTHORIZATION_MODE == "RBAC"
  CERTS_MASTER_SCRIPT = File.join(File.dirname(__FILE__), "tls/make-certs-master-rbac.sh")
else
  CERTS_MASTER_SCRIPT = File.join(File.dirname(__FILE__), "tls/make-certs-master.sh")
end

CERTS_MASTER_CONF = File.join(File.dirname(__FILE__), "tls/openssl-master.cnf.tmpl")
CERTS_NODE_SCRIPT = File.join(File.dirname(__FILE__), "tls/make-certs-node.sh")
CERTS_NODE_CONF = File.join(File.dirname(__FILE__), "tls/openssl-node.cnf.tmpl")

MANIFESTS_DIR = Pathname.getwd().join("manifests")

USE_DOCKERCFG = ENV["USE_DOCKERCFG"] || false
DOCKERCFG = File.expand_path(ENV["DOCKERCFG"] || "~/.dockercfg")

DOCKER_OPTIONS = ENV["DOCKER_OPTIONS"] || ""

KUBERNETES_VERSION = ENV["KUBERNETES_VERSION"] || "1.10.2"

CHANNEL = ENV["CHANNEL"] || "alpha"

#if CHANNEL != 'alpha'
#  puts "============================================================================="
#  puts "As this is a fastly evolving technology CoreOS' alpha channel is the only one"
#  puts "expected to behave reliably. While one can invoke the beta or stable channels"
#  puts "please be aware that your mileage may vary a whole lot."
#  puts "So, before submitting a bug, in this project, or upstreams (either kubernetes"
#  puts "or CoreOS) please make sure it (also) happens in the (default) alpha channel."
#  puts "============================================================================="
#end

COREOS_VERSION = ENV["COREOS_VERSION"] || "latest"
upstream = "http://#{CHANNEL}.release.core-os.net/amd64-usr/#{COREOS_VERSION}"
if COREOS_VERSION == "latest"
  upstream = "http://#{CHANNEL}.release.core-os.net/amd64-usr/current"
  url = "#{upstream}/version.txt"
  Object.redefine_const(:COREOS_VERSION,
                        open(url).read().scan(/COREOS_VERSION=.*/)[0].gsub("COREOS_VERSION=", ""))
end

NODES = ENV["NODES"] || 2

MASTER_MEM = ENV["MASTER_MEM"] || 1024
MASTER_CPUS = ENV["MASTER_CPUS"] || 2

NODE_MEM = ENV["NODE_MEM"] || 2048
NODE_CPUS = ENV["NODE_CPUS"] || 2

BASE_IP_ADDR = ENV["BASE_IP_ADDR"] || "172.17.8"

DNS_DOMAIN = ENV["DNS_DOMAIN"] || "cluster.local"

SERIAL_LOGGING = (ENV["SERIAL_LOGGING"].to_s.downcase == "true")
GUI = (ENV["GUI"].to_s.downcase == "true")
USE_KUBE_UI = ENV["USE_KUBE_UI"] || false

BOX_TIMEOUT_COUNT = ENV["BOX_TIMEOUT_COUNT"] || 50

if enable_proxy
  HTTP_PROXY = ENV["HTTP_PROXY"] || ENV["http_proxy"]
  HTTPS_PROXY = ENV["HTTPS_PROXY"] || ENV["https_proxy"]
  NO_PROXY = ENV["NO_PROXY"] || ENV["no_proxy"] || "localhost"
end

REMOVE_VAGRANTFILE_USER_DATA_BEFORE_HALT = (ENV["REMOVE_VAGRANTFILE_USER_DATA_BEFORE_HALT"].to_s.downcase == "true")
# if this is set true, remember to use --provision when executing vagrant up / reload

# Read YAML file with mountpoint details
MOUNT_POINTS = YAML::load_file(File.join(File.dirname(__FILE__), "synced_folders.yaml"))

# CLUSTER_CIDR is the CIDR used for pod networking
CLUSTER_CIDR = ENV["CLUSTER_CIDR"] || "10.244.0.0/16"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # always use host timezone in VMs
  config.timezone.value = :host

  # always use Vagrants' insecure key
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  config.vm.box = "coreos-#{CHANNEL}"
  config.vm.box_version = "= #{COREOS_VERSION}"
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
    v.functional_vboxsf = false
    v.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
  end
  config.vm.provider :parallels do |p|
    p.update_guest_tools = false
    p.check_guest_tools = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  # setup VM proxy to system proxy environment
  if Vagrant.has_plugin?("vagrant-proxyconf") && enable_proxy
    config.proxy.http = HTTP_PROXY
    config.proxy.https = HTTPS_PROXY
    # most http tools, like wget and curl do not undestand IP range
    # thus adding each node one by one to no_proxy
    no_proxies = NO_PROXY.split(",")
    (1..(NODES.to_i + 1)).each do |i|
      vm_ip_addr = "#{BASE_IP_ADDR}.#{i + 100}"
      Object.redefine_const(:NO_PROXY,
                            "#{NO_PROXY},#{vm_ip_addr}") unless no_proxies.include?(vm_ip_addr)
    end
    config.proxy.no_proxy = NO_PROXY
    # proxyconf plugin use wrong approach to set Docker proxy for CoreOS
    # force proxyconf to skip Docker proxy setup
    config.proxy.enabled = {docker: false}
  end

  (1..(NODES.to_i + 1)).each do |i|
    if i == 1
      hostname = "master"
      ETCD_SEED_CLUSTER = "#{hostname}=http://#{BASE_IP_ADDR}.#{i + 100}:2380"
      cfg = MASTER_YAML
      memory = MASTER_MEM
      cpus = MASTER_CPUS
      MASTER_IP = "#{BASE_IP_ADDR}.#{i + 100}"
    else
      hostname = "node-%02d" % (i - 1)
      cfg = NODE_YAML
      memory = NODE_MEM
      cpus = NODE_CPUS
    end

    config.vm.define vmName = hostname do |kHost|
      kHost.vm.hostname = vmName

      # suspend / resume is hard to be properly supported because we have no way
      # to assure the fully deterministic behavior of whatever is inside the VMs
      # when faced with XXL clock gaps... so we just disable this functionality.
      kHost.trigger.reject [:suspend, :resume] do
        info "'vagrant suspend' and 'vagrant resume' are disabled."
        info "- please do use 'vagrant halt' and 'vagrant up' instead."
      end

      config.trigger.instead_of :reload do
        exec "vagrant halt && vagrant up"
        exit
      end

      # vagrant-triggers has no concept of global triggers so to avoid having
      # then to run as many times as the total number of VMs we only call them
      # in the master (re: emyl/vagrant-triggers#13)...
      if vmName == "master"
        kHost.trigger.before [:up, :provision] do
          info "#{Time.now}: setting up Kubernetes master..."
          info "Setting Kubernetes version #{KUBERNETES_VERSION}"

          # create setup file
          setupFile = "#{__dir__}/temp/setup"
          # find and replace kubernetes version and master IP in setup file
          setupData = File.read("setup.tmpl")
          setupData = setupData.gsub("__KUBERNETES_VERSION__", KUBERNETES_VERSION)
          setupData = setupData.gsub("__MASTER_IP__", MASTER_IP)
          if enable_proxy
            # remove __PROXY_LINE__ flag and set __NO_PROXY__
            setupData = setupData.gsub("__PROXY_LINE__", "")
            setupData = setupData.gsub("__NO_PROXY__", NO_PROXY)
          else
            # remove lines that start with __PROXY_LINE__
            setupData = setupData.gsub(/^\s*__PROXY_LINE__.*$\n/, "")
          end
          # write new setup data to setup file
          File.open(setupFile, "wb") do |f|
            f.write(setupData)
          end

          # give setup file executable permissions
          system "chmod +x temp/setup"

          system "#{__dir__}/plugins/dns/coredns/deploy.sh 10.100.0.10/24 #{DNS_DOMAIN} #{__dir__}/plugins/dns/coredns/coredns.yaml.sed > #{__dir__}/temp/coredns-deployment.yaml"
        end

        kHost.trigger.after [:up, :resume] do
          unless OS.windows?
            info "Sanitizing stuff..."
            system "ssh-add ~/.vagrant.d/insecure_private_key"
            system "rm -rf ~/.fleetctl/known_hosts"
          end
        end

        kHost.trigger.after [:up] do
          info "Waiting for Kubernetes master to become ready..."
          j, uri, res = 0, URI("http://#{MASTER_IP}:8080"), nil
          loop do
            j += 1
            begin
              res = Net::HTTP.get_response(uri)
            rescue
              sleep 10
            end
            break if res.is_a? Net::HTTPSuccess or j >= BOX_TIMEOUT_COUNT
          end
          if res.is_a? Net::HTTPSuccess
            info "#{Time.now}: successfully deployed #{vmName}"
          else
            info "#{Time.now}: failed to deploy #{vmName} within timeout count of #{BOX_TIMEOUT_COUNT}"
          end

          info "Installing kubectl for the Kubernetes version we just bootstrapped..."
          if OS.windows?
            run_remote "sudo -u core /bin/sh /home/core/kubectlsetup install"
          else
            system "./temp/setup install"
          end

          # set cluster
          if OS.windows?
            run_remote "/opt/bin/kubectl config set-cluster default-cluster --server=https://#{MASTER_IP} --certificate-authority=/vagrant/artifacts/tls/ca.pem"
            run_remote "/opt/bin/kubectl config set-credentials default-admin --certificate-authority=/vagrant/artifacts/tls/ca.pem --client-key=/vagrant/artifacts/tls/admin-key.pem --client-certificate=/vagrant/artifacts/tls/admin.pem"
            run_remote "/opt/bin/kubectl config set-context local --cluster=default-cluster --user=default-admin"
            run_remote "/opt/bin/kubectl config use-context local"
          else
            system "kubectl config set-cluster default-cluster --server=https://#{MASTER_IP} --certificate-authority=artifacts/tls/ca.pem"
            system "kubectl config set-credentials default-admin --certificate-authority=artifacts/tls/ca.pem --client-key=artifacts/tls/admin-key.pem --client-certificate=artifacts/tls/admin.pem"
            system "kubectl config set-context local --cluster=default-cluster --user=default-admin"
            system "kubectl config use-context local"
          end

          info "Configuring Calico..."

          # Replace __CLUSTER_CIDR__ in calico.yaml.tmpl with the value of CLUSTER_CIDR
          calicoTmpl = File.read("#{__dir__}/plugins/calico/calico.yaml.tmpl")
          calicoTmpl = calicoTmpl.gsub("__CLUSTER_CIDR__", CLUSTER_CIDR)
          File.open("#{__dir__}/temp/calico.yaml", "wb") do |f|
            f.write(calicoTmpl)
          end

          # Install Calico
          if OS.windows?
            if AUTHORIZATION_MODE == "RBAC"
              run_remote "/opt/bin/kubectl apply -f /home/core/calico-rbac.yaml"
            end
            run_remote "/opt/bin/kubectl apply -f /home/core/calico.yaml"
          else
            if AUTHORIZATION_MODE == "RBAC"
              system "kubectl apply -f plugins/calico/calico-rbac.yaml"
            end
            system "kubectl apply -f temp/calico.yaml"
          end

          info "Configuring Kubernetes DNS..."

          res, uri.path = nil, "/api/v1/namespaces/kube-system/deployment/coredns"
          begin
            res = Net::HTTP.get_response(uri)
          rescue
          end
          if not res.is_a? Net::HTTPSuccess
            if OS.windows?
              run_remote "/opt/bin/kubectl create -f /home/core/coredns-deployment.yaml"
            else
              system "kubectl create -f temp/coredns-deployment.yaml"
            end
          end

          if USE_KUBE_UI
            info "Configuring Kubernetes Dashboard..."

            if OS.windows?
              run_remote "/opt/bin/kubectl apply -f /home/core/dashboard.yaml"
              if AUTHORIZATION_MODE == "RBAC"
                run_remote "/opt/bin/kubectl apply -f /home/core/dashboard-rbac.yaml"
              end
            else
              system "kubectl apply -f plugins/dashboard/dashboard.yaml"
              if AUTHORIZATION_MODE == "RBAC"
                system "kubectl apply -f plugins/dashboard/dashboard-rbac.yaml"
              end
            end

            info "Kubernetes Dashboard will be available at http://#{MASTER_IP}:8080/ui/"
          end
        end

        # copy setup files to master vm if host is windows
        if OS.windows?
          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "temp/setup"), :destination => "/home/core/kubectlsetup"

          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "plugins/calico/calico-rbac.yaml"), :destination => "/home/core/calico-rbac.yaml"
          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "temp/calico.yaml"), :destination => "/home/core/calico.yaml"

          kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "temp/coredns-deployment.yaml"), :destination => "/home/core/coredns-deployment.yaml"

          if USE_KUBE_UI
            kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "plugins/dashboard/dashboard-rbac.yaml"), :destination => "/home/core/dashboard-rbac.yaml"
            kHost.vm.provision :file, :source => File.join(File.dirname(__FILE__), "plugins/dashboard/dashboard.yaml"), :destination => "/home/core/dashboard.yaml"
          end
        end

        # clean temp directory after master is destroyed
        kHost.trigger.after [:destroy] do
          FileUtils.rm_rf(Dir.glob("#{__dir__}/temp/*"))
          FileUtils.rm_rf(Dir.glob("#{__dir__}/artifacts/tls/*"))
        end
      end

      if vmName == "node-%02d" % (i - 1)
        kHost.trigger.before [:up, :provision] do
          info "#{Time.now}: setting up node..."
        end

        kHost.trigger.after [:up] do
          info "Waiting for Kubernetes worker [node-%02d" % (i - 1) + "] to become ready..."
          j, uri, hasResponse = 0, URI("http://#{BASE_IP_ADDR}.#{i + 100}:10250"), false
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
            break if hasResponse or j >= BOX_TIMEOUT_COUNT
          end
          if hasResponse
            info "#{Time.now}: successfully deployed #{vmName}"
          else
            info "#{Time.now}: failed to deploy #{vmName} within timeout count of #{BOX_TIMEOUT_COUNT}"
          end
        end
      end

      kHost.trigger.before [:halt, :reload] do
        if REMOVE_VAGRANTFILE_USER_DATA_BEFORE_HALT
          run_remote "sudo rm -f /var/lib/coreos-vagrant/vagrantfile-user-data"
        end
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
      ["vmware_fusion", "vmware_workstation"].each do |h|
        kHost.vm.provider h do |v|
          v.vmx["memsize"] = memory
          v.vmx["numvcpus"] = cpus
          v.vmx["virtualHW.version"] = 10
        end
      end
      ["parallels", "virtualbox"].each do |h|
        kHost.vm.provider h do |n|
          n.memory = memory
          n.cpus = cpus
        end
      end

      kHost.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{i + 100}"

      # you can override this in synced_folders.yaml
      kHost.vm.synced_folder ".", "/vagrant", disabled: true

      begin
        MOUNT_POINTS.each do |mount|
          mount_options = ""
          disabled = false
          nfs = true
          if mount["mount_options"]
            mount_options = mount["mount_options"]
          end
          if mount["disabled"]
            disabled = mount["disabled"]
          end
          if mount["nfs"]
            nfs = mount["nfs"]
          end
          if File.exist?(File.expand_path("#{mount["source"]}"))
            if mount["destination"]
              kHost.vm.synced_folder "#{mount["source"]}", "#{mount["destination"]}",
                id: "#{mount["name"]}",
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

      # Copy TLS stuff
      if vmName == "master"
        kHost.vm.provision :file, :source => "#{CERTS_MASTER_SCRIPT}", :destination => "/tmp/make-certs.sh"
        kHost.vm.provision :file, :source => "#{CERTS_MASTER_CONF}", :destination => "/tmp/openssl.cnf"
        kHost.vm.provision :shell, :privileged => true,
                                   inline: <<-EOF
          sed -i"*" "s|__MASTER_IP__|#{MASTER_IP}|g" /tmp/openssl.cnf
          sed -i"*" "s|__DNS_DOMAIN__|#{DNS_DOMAIN}|g" /tmp/openssl.cnf
        EOF
        kHost.vm.provision :shell, run: "always" do |s|
          s.inline = "mkdir -p /etc/kubernetes && cp -R /vagrant/tls/master-kubeconfig.yaml /etc/kubernetes/master-kubeconfig.yaml"
          s.privileged = true
        end
      else
        kHost.vm.provision :file, :source => "#{CERTS_NODE_SCRIPT}", :destination => "/tmp/make-certs.sh"
        kHost.vm.provision :file, :source => "#{CERTS_NODE_CONF}", :destination => "/tmp/openssl.cnf"
        kHost.vm.provision :file, :source => "#{CERTS_NODE_CONF}", :destination => "/tmp/openssl.cnf"
        kHost.vm.provision :shell, run: "always" do |s|
          s.inline = "mkdir -p /etc/kubernetes && cp -R /vagrant/tls/node-kubeconfig.yaml /etc/kubernetes/node-kubeconfig.yaml"
          s.privileged = true
        end
        kHost.vm.provision :shell, :privileged => true,
                                   inline: <<-EOF
          sed -i"*" "s|__NODE_IP__|#{BASE_IP_ADDR}.#{i + 100}|g" /tmp/openssl.cnf
          sed -i"*" "s|__MASTER_IP__|#{MASTER_IP}|g" /etc/kubernetes/node-kubeconfig.yaml
        EOF
      end

      # Process Kubernetes manifests, depending on node type
      begin
        if vmName == "master"
          if AUTHORIZATION_MODE == "RBAC"
            kHost.vm.provision :shell, run: "always" do |s|
              s.inline = "mkdir -p /etc/kubernetes/manifests && find /vagrant/manifests/master* ! -name master-apiserver.yaml -exec cp -t /etc/kubernetes/manifests {} +"
              s.privileged = true
            end
          else
            kHost.vm.provision :shell, run: "always" do |s|
              s.inline = "mkdir -p /etc/kubernetes/manifests && cp -R /vagrant/manifests/master* /etc/kubernetes/manifests"
              s.privileged = true
            end
          end
        else
          kHost.vm.provision :shell, run: "always" do |s|
            s.inline = "mkdir -p /etc/kubernetes/manifests && cp -R /vagrant/manifests/node* /etc/kubernetes/manifests/"
            s.privileged = true
          end
        end
        kHost.vm.provision :shell, run: "always", :privileged => true,
                                   inline: <<-EOF
          sed -i"*" "s,__RELEASE__,v#{KUBERNETES_VERSION},g" /etc/kubernetes/manifests/*.yaml
          sed -i"*" "s|__MASTER_IP__|#{MASTER_IP}|g" /etc/kubernetes/manifests/*.yaml
          sed -i"*" "s|__DNS_DOMAIN__|#{DNS_DOMAIN}|g" /etc/kubernetes/manifests/*.yaml
          sed -i"*" "s|__CLUSTER_CIDR__|#{CLUSTER_CIDR}|g" /etc/kubernetes/manifests/*.yaml
        EOF
      end

      # Process vagrantfile
      if File.exist?(cfg)
        kHost.vm.provision :file, :source => "#{cfg}", :destination => "/tmp/vagrantfile-user-data"
        if enable_proxy
          kHost.vm.provision :shell, :privileged => true,
                                     inline: <<-EOF
          sed -i"*" "s|__PROXY_LINE__||g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__HTTP_PROXY__|#{HTTP_PROXY}|g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__HTTPS_PROXY__|#{HTTPS_PROXY}|g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__NO_PROXY__|#{NO_PROXY}|g" /tmp/vagrantfile-user-data
          EOF
        end
        kHost.vm.provision :shell, :privileged => true,
                                   inline: <<-EOF
          sed -i"*" "/__PROXY_LINE__/d" /tmp/vagrantfile-user-data
          sed -i"*" "s,__DOCKER_OPTIONS__,#{DOCKER_OPTIONS},g" /tmp/vagrantfile-user-data
          sed -i"*" "s,__RELEASE__,v#{KUBERNETES_VERSION},g" /tmp/vagrantfile-user-data
          sed -i"*" "s,__CHANNEL__,#{CHANNEL},g" /tmp/vagrantfile-user-data
          sed -i"*" "s,__NAME__,#{hostname},g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__MASTER_IP__|#{MASTER_IP}|g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__DNS_DOMAIN__|#{DNS_DOMAIN}|g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__ETCD_SEED_CLUSTER__|#{ETCD_SEED_CLUSTER}|g" /tmp/vagrantfile-user-data
          sed -i"*" "s|__CLUSTER_CIDR__|#{CLUSTER_CIDR}|g" /tmp/vagrantfile-user-data
          mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
        EOF
      end
    end
  end
end
