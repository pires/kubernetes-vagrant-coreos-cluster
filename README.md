# kubernetes-vagrant-coreos-cluster
Turnkey **[Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes)**
cluster setup with **[Vagrant](https://www.vagrantup.com)** (1.7.2+) and
**[CoreOS](https://coreos.com)**.

####If you're lazy, or in a hurry, jump to the [TL;DR](#tldr) section.

## Pre-requisites

 * **[Vagrant](https://www.vagrantup.com)**
 * a supported Vagrant hypervisor
 	* **[Virtualbox](https://www.virtualbox.org)** (the default)
 	* **[Parallels Desktop](http://www.parallels.com/eu/products/desktop/)**
 	* **[VMware Fusion](http://www.vmware.com/products/fusion)** or **[VMware Workstation](http://www.vmware.com/products/workstation)**

### MacOS X

On **MacOS X** (and assuming you have [homebrew](http://brew.sh) already installed) run

```
brew update
brew install wget
```

### Windows

The [vagrant-winnfsd plugin](https://github.com/GM-Alex/vagrant-winnfsd) will be installed in order to enable NFS shares.

## Deploy Kubernetes

Current ```Vagrantfile``` will bootstrap one VM with everything needed to become a Kubernetes _master_ and, by default, a couple VMs with everything needed to become Kubernetes minions.
You can change the number of minions and/or the Kubernetes version by setting environment variables **NUM_INSTANCES** and **KUBERNETES_VERSION**, respectively. [You can find more details below](#customization).

```
vagrant up
```

### Linux or MacOS host

Kubernetes cluster is ready. but you need to set-up some environment variables that we have already provisioned for you. In the current terminal windo, run:

```
source ~/.bash_profile
```

New terminal windows will have this set for you.

### Windows host

On Windows systems, `kubectl` is installed on the `master` node, in the ```/opt/bin``` directory. To manage your Kubernetes cluster, `ssh` into the `master` node and run `kubectl` from there.

```
vagrant ssh master
kubectl cluster-info
```

## Clean-up

```
vagrant destroy
```

If you've set `NUM_INSTANCES` or any other variable when deploying, please make sure you set it in `vagrant destroy` call above, like:

```
NUM_INSTANCES=3 vagrant destroy
```

## Notes about hypervisors

### Virtualbox

**VirtualBox** is the default hypervisor, and you'll probably need to disable its DHCP server
```
VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
```

### Parallels

If you are using **Parallels Desktop**, you need to install **[vagrant-parallels](http://parallels.github.io/vagrant-parallels/docs/)** provider 
```
vagrant plugin install vagrant-parallels
```
Then just add ```--provider parallels``` to the ```vagrant up``` invocations above.

### VMware
If you are using one of the **VMware** hypervisors you must **[buy](http://www.vagrantup.com/vmware)** the matching  provider and, depending on your case, just add either ```--provider vmware-fusion``` or ```--provider vmware-workstation``` to the ```vagrant up``` invocations above.

## Private Docker Repositories

If you want to use Docker private repositories look for **DOCKERCFG** bellow.

## Customization
### Environment variables
Most aspects of your cluster setup can be customized with environment variables. Right now the available ones are:

 - **NUM_INSTANCES** sets the number of nodes (minions).

   Defaults to **2**.
 - **UPDATE_CHANNEL** sets the default CoreOS channel to be used in the VMs.

   Defaults to **alpha**.

   While by convenience, we allow an user to optionally consume CoreOS' *beta* or *stable* channels please do note that as both Kubernetes and CoreOS are quickly evolving platforms we only expect our setup to behave reliably on top of CoreOS' _alpha_ channel.
   So, **before submitting a bug**, either in [this](https://github.com/pires/kubernetes-vagrant-coreos-cluster/issues) project, or in ([Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes/issues) or [CoreOS](https://github.com/coreos/bugs/issues)) **make sure it** (also) **happens in the** (default) **_alpha_ channel** :smile:
 - **COREOS_VERSION** will set the specific CoreOS release (from the given channel) to be used.

   Default is to use whatever is the **latest** one from the given channel.
 - **SERIAL_LOGGING** if set to *true* will allow logging from the VMs' serial console.

   Defaults to **false**. Only use this if you *really* know what you are doing.
 - **MASTER_MEM** sets the master's VM memory.

   Defaults to **512** (in MB)
 - **MASTER_CPUS** sets the number os vCPUs to be used by the master's VM.

   Defaults to **1**.
 - **NODE_MEM** sets the worker nodes' (aka minions in Kubernetes lingo) VM memory.

   Defaults to **1024** (in MB)
 - **NODE_CPUS** sets the number os vCPUs to be used by the minions's VMs.

   Defaults to **1**.
 - **DOCKERCFG** sets the location of your private docker repositories (and keys) configuration. However, this is only usable if you set **USE_DOCKERCFG=true**.

   Defaults to "**~/.dockercfg**".

   You can create/update a *~/.dockercfg* file at any time
   by running `docker login <registry>.<domain>`. All nodes will get it automatically,
   at 'vagrant up', given any modification or update to that file.

 - **KUBERNETES_VERSION** defines the specific kubernetes version being used.

   Defaults to `0.17.0`.
   Versions prior to `0.17.0` **won't work** with current cloud-config files.

 - **CLOUD_PROVIDER** defines the specific cloud provider being used. This is useful, for instance, if you're relying on kubernetes to set load-balancers for your services.

   [Possible values are `gce`, `gke`, `aws`, `azure`, `vagrant`, `vsphere`, `libvirt-coreos` and `juju`](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/cluster/kube-env.sh#L17). Defaults to `vagrant`.


So, in order to start, say, a Kubernetes cluster with 3 minion nodes, 2GB of RAM and 2 vCPUs per node one just would do...

```
NODE_MEM=2048 NODE_CPUS=2 NUM_INSTANCES=3 vagrant up
```

**Please do note** that if you were using non default settings to startup your
cluster you *must* also use those exact settings when invoking
`vagrant {up,ssh,status,destroy}` to communicate with any of the nodes in the cluster as otherwise
things may not behave as you'd expect.

### Synced Folders
You can automatically mount in your *guest* VMs, at startup, an arbitrary
number of local folders in your host machine by populating accordingly the
`synced_folders.yaml` file in your `Vagrantfile` directory. For each folder
you which to mount the allowed syntax is...

```yaml
# the 'id' of this mount point. needs to be unique.
- name: foobar
# the host source directory to share with the guest(s).
  source: /foo
# the path to mount ${source} above on guest(s)
  destination: /bar
# the mount type. only NFS makes sense as, presently, we are not shipping
# hypervisor specific guest tools. defaults to `true`.
  nfs: true
# additional options to pass to the mount command on the guest(s)
# if not set the Vagrant NFS defaults will be used.
  mount_options: 'nolock,vers=3,udp,noatime'
# if the mount is enabled or disabled by default. default is `true`.
  disabled: false
```

## TL;DR

```
vagrant up
source ~/.bash_profile
```

This will start one `master` and two `minion` nodes, download Kubernetes binaries start all needed services.
A Docker mirror cache will be provisioned in the `master`, to speed up container provisioning. This can take some time depending on your Internet connection speed.

Please do note that, at any time, you can change the number of `minions` by setting the `NUM_INSTANCES` value in subsequent `vagrant up` invocations.

### Usage

Congratulations! You're now ready to use your Kubernetes cluster.

If you just want to test something simple, start with [Kubernetes examples]
(https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).

For a more elaborate scenario [here]
(https://github.com/pires/kubernetes-elasticsearch-cluster) you'll find all
you need to get a scalable Elasticsearch cluster on top of Kubernetes in no
time.

## Licensing

This work is [open source](http://opensource.org/osd), and is licensed under the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
