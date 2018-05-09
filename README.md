# kubernetes-vagrant-coreos-cluster
Turnkey **[Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes)**
cluster setup with **[Vagrant 2.1.1+](https://www.vagrantup.com)** and
**[CoreOS](https://coreos.com)**.

If you're lazy, or in a hurry, jump to the [TL;DR](#tldr) section.

## Pre-requisites

 * **[Vagrant 2.1.1+](https://www.vagrantup.com)**
 * a supported Vagrant hypervisor:
 	* **[Virtualbox](https://www.virtualbox.org)** (the default)
 	* **[Parallels Desktop](http://www.parallels.com/eu/products/desktop/)**
 	* **[VMware Fusion](http://www.vmware.com/products/fusion)** or **[VMware Workstation](http://www.vmware.com/products/workstation)**

### MacOS X

On **MacOS X** (and assuming you have [homebrew](http://brew.sh) already installed) run

```
brew install wget
```

### Windows

- The [vagrant-winnfsd plugin](https://github.com/GM-Alex/vagrant-winnfsd) will be installed in order to enable NFS shares.
- The project will run some bash script under the VirtualMachines. These scripts line ending need to be in LF. Git for windows set `core.autocrlf true` by default at the installation time. When you clone this project repository, this parameter (set to true) ask git to change all line ending to CRLF. This behavior need to be changed before cloning the repository (or after for each files by hand). We recommand to turn this to off by running `git config --global core.autocrlf false` and `git config --global core.eol lf` before cloning. Then, after cloning, do not forget to turn the behavior back if you want to run other windows projects: `git config --global core.autocrlf true` and `git config --global core.eol crlf`.

## Deploy Kubernetes

Current ```Vagrantfile``` will bootstrap one VM with everything needed to become a Kubernetes _master_ and, by default, a couple VMs with everything needed to become Kubernetes worker nodes.
You can change the number of worker nodes and/or the Kubernetes version by setting environment variables **NODES** and **KUBERNETES_VERSION**, respectively. [You can find more details below](#customization).

```
vagrant up
```

### Linux or MacOS host

Kubernetes cluster is ready. Use `kubectl` to manage it.

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

If you've set `NODES` or any other variable when deploying, please make sure you set it in `vagrant destroy` call above, like:

```
NODES=3 vagrant destroy -f
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
If you are using one of the **VMware** hypervisors you must **[buy](http://www.vagrantup.com/vmware)** the matching  provider and, depending on your case, just add either ```--provider vmware_fusion``` or ```--provider vmware_workstation``` to the ```vagrant up``` invocations above.

## Private Docker Repositories

If you want to use Docker private repositories look for **DOCKERCFG** bellow.

## Customization
### Environment variables
Most aspects of your cluster setup can be customized with environment variables. Right now the available ones are:

 - **NODES** sets the number of nodes (workers).

   Defaults to **2**.
 - **CHANNEL** sets the default CoreOS channel to be used in the VMs.

   Defaults to **alpha**.

   While by convenience, we allow an user to optionally consume CoreOS' *beta* or *stable* channels please do note that as both Kubernetes and CoreOS are quickly evolving platforms we only expect our setup to behave reliably on top of CoreOS' _alpha_ channel.
   So, **before submitting a bug**, either in [this](https://github.com/pires/kubernetes-vagrant-coreos-cluster/issues) project, or in ([Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes/issues) or [CoreOS](https://github.com/coreos/bugs/issues)) **make sure it** (also) **happens in the** (default) **_alpha_ channel** :smile:
 - **COREOS_VERSION** will set the specific CoreOS release (from the given channel) to be used.

   Default is to use whatever is the **latest** one from the given channel.
 - **SERIAL_LOGGING** if set to *true* will allow logging from the VMs' serial console.

   Defaults to **false**. Only use this if you *really* know what you are doing.
 - **MASTER_MEM** sets the master node VM memory.

   Defaults to **1024** (in MB)
 - **MASTER_CPUS** sets the number of vCPUs to be used by the master VM.

   Defaults to **2**.
 - **NODE_MEM** sets the worker nodes VM memory.

   Defaults to **2048** (in MB)
 - **NODE_CPUS** sets the number of vCPUs to be used by node VMs.

   Defaults to **2**.
 - **DOCKERCFG** sets the location of your private docker repositories (and keys) configuration. However, this is only usable if you set **USE_DOCKERCFG=true**.

   Defaults to "**~/.dockercfg**".

   You can create/update a *~/.dockercfg* file at any time
   by running `docker login <registry>.<domain>`. All nodes will get it automatically,
   at 'vagrant up', given any modification or update to that file.

 - **DOCKER_OPTIONS** sets the additional `DOCKER_OPTS` for docker service on both master and the nodes. Useful for adding params such as `--insecure-registry`.

 - **KUBERNETES_VERSION** defines the specific kubernetes version being used.

   Defaults to `1.10.2`.
   Versions prior to `1.10.0` **may not work** with current cloud-configs and Kubernetes descriptors.

 - **USE_KUBE_UI** defines whether to deploy or not the Kubernetes UI

   Defaults to `false`.

 - **AUTHORIZATION_MODE** setting this to `RBAC` enables RBAC for the kubernetes cluster.

   Defaults to `AlwaysAllow`.

 - **CLUSTER_CIDR** defines the CIDR to be used for pod networking. This CIDR must not overlap with `10.100.0.0/16`.

   Defaults to `10.244.0.0/16`.

So, in order to start, say, a Kubernetes cluster with 3 worker nodes, 4GB of RAM and 4 vCPUs per node one just would run:

```
NODE_MEM=4096 NODE_CPUS=4 NODES=3 vagrant up
```

or with Kubernetes UI:

```
NODE_MEM=4096 NODE_CPUS=4 NODES=3 USE_KUBE_UI=true vagrant up
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

**ATTENTION:** Don't remove `/vagrant` entry.

## TL;DR

```
vagrant up
```

This will start one `master` and two `worker` nodes, download Kubernetes binaries start all needed services.
A Docker mirror cache will be provisioned in the `master`, to speed up container provisioning. This can take some time depending on your Internet connection speed.

Please do note that, at any time, you can change the number of `worker` nodes by setting the `NODES` value in subsequent `vagrant up` invocations.

### Usage

Congratulations! You're now ready to use your Kubernetes cluster.

If you just want to test something simple, start with [Kubernetes examples]
(https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).

For a more elaborate scenario [here]
(https://github.com/pires/kubernetes-elasticsearch-cluster) you'll find all
you need to get a scalable Elasticsearch cluster on top of Kubernetes in no
time.

## Troubleshooting

#### Vagrant displays a warning message when running!

Vagrant 2.1 integrated support for triggers as a core functionality. However,
this change is not compatible with the
[`vagrant-triggers`](https://github.com/emyl/vagrant-triggers) community plugin
we were and still are using. Since we require this plugin, Vagrant will show the
following warning:

```
WARNING: Vagrant has detected the `vagrant-triggers` plugin. This plugin conflicts
with the internal triggers implementation. Please uninstall the `vagrant-triggers`
plugin and run the command again if you wish to use the core trigger feature. To
uninstall the plugin, run the command shown below:

  vagrant plugin uninstall vagrant-triggers

Note that the community plugin `vagrant-triggers` and the core trigger feature
in Vagrant do not have compatible syntax.

To disable this warning, set the environment variable `VAGRANT_USE_VAGRANT_TRIGGERS`.
```

This warning is harmless and only means that we are using the community plugin
instead of the core functionality. To disable it, set the
`VAGRANT_USE_VAGRANT_TRIGGERS` environment variable to `false` before running
`vagrant`:

```
$ VAGRANT_USE_VAGRANT_TRIGGERS=false NODES=2 vagrant up
```

#### I'm getting errors while waiting for Kubernetes master to become ready on a MacOS host!

If you see something like this in the log:
```
==> master: Waiting for Kubernetes master to become ready...
error: unable to load file "temp/dns-controller.yaml": unable to connect to a server to handle "replicationcontrollers": couldn't read version from server: Get https://10.245.1.2/api: dial tcp 10.245.1.2:443: i/o timeout
error: no objects passed to create
```
You probably have a pre-existing Kubernetes config file on your system at `~/.kube/config`. Delete or move that file and try again.

#### Kubernetes Dashboard asks for either a Kubeconfig or token!

This behavior is expected in latest versions of the Kubernetes Dashboard, since
different people may need to use the Kubernetes Dashboard with different
permissions. Since we deploy a service account with
[administrative privileges](https://github.com/kubernetes/dashboard/wiki/Access-control#admin-privileges)
you should just click _Skip_. Everything will work as expected.

## Licensing

This work is [open source](http://opensource.org/osd), and is licensed under the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
