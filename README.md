# kubernetes-vagrant-coreos-cluster
**[Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes)** (currently 0.9.3)
cluster made easy with [Vagrant](https://www.vagrantup.com) (1.7.2+) and
**[CoreOS](https://coreos.com)** [(alpha/593.0.0)](https://coreos.com/releases/).

> Please see [bellow](#customization) for how to play with other CoreOS/kubernetes
> combos, caveats included.


## Pre-requisites

 * **[Vagrant](https://www.vagrantup.com)**
 * a supported Vagrant hypervisor
 	* **[Virtualbox](https://www.virtualbox.org)** (the default)
 	* **[Parallels Desktop](http://www.parallels.com/eu/products/desktop/)**
 	* **[VMware Fusion](http://www.vmware.com/products/fusion)** or **[VMware Workstation](http://www.vmware.com/products/workstation)**
 * some needed userland
 	* **kubectl** (required to manage your kubernetes cluster)
 	* **fleetctl** (optional for *debugging* **[fleet](http://github.com/coreos/fleet)**)
 	* **etcdctl** (optional for *debugging* **[etcd](http://github.com/coreos/fleet)**)

	 > ### fleetctl, etcdctl, kubectl
 	>
 	> On **MacOS X**, do, in advance
 	> ```
 	> brew install wget fleetctl etcdctl
 	> ```
 	>
 	> Now, download the *kubectl* binary into */usr/local/bin*, which should
 	> be (and most probably is) set in your shell's *$PATH*:
 	>	> ```
 	>	> ./kubLocalSetup install
	 >	> ```
 	>  > You may specify a different *kubectl* version via the
 	> ```KUBERNETES_VERSION``` environment variable.
 	>
 	> Finally, let's set all needed environment variables in current shell:
 	> ```
 	> $(./kubLocalSetup shellinit)
 	> ```
 	>
 	> If you want to make that persistent across shells and reboots do instead:
 	> ```
 	> ./kubLocalSetup shellinit >> ˜/.bash_profile
 	> ```
 	>
 	> If you want to validate the environment variables we just set, run:
 	> ```
 	> ./kubLocalSetup shellinit
 	> ```

## Master

Current ```Vagrantfile``` will bootstrap one VM with everything it needs to become a Kubernetes _master_.
```
vagrant up master
```

Verify that ```fleet``` sees it
```
fleetctl list-machines
```

You should see something like
```
MACHINE		IP		METADATA
dd0ee115...	172.17.8.101	role=master
```

## Minions

Current ```Vagrantfile``` will bootstrap two VMs, by default, with everything needed to have two Kubernetes minions. You can
change this by setting the **NUM_INSTANCES** environment variable (explained below).

```
vagrant up node-01 node-02
```

Verify ```fleet``` again, just for the sake of it
```
fleetctl list-machines
```

You should see something like
```
MACHINE		IP		METADATA
dd0ee115...	172.17.8.101	role=master
74a8dc8c...	172.17.8.102	role=minion
c93da9ff...	172.17.8.103    role=minion
```

## Notes about hypervisors
- if you are using **VirtualBox** you don't need to do anything *extra* as it is the default Vagrant hypervisor.
- If you are using **Parallels Desktop** you need to have installed the **[vagrant-parallels](http://parallels.github.io/vagrant-parallels/docs/)** provider which you can do by just doing ```vagrant plugin install vagrant-parallels```.
Then just add ```--provider parallels``` to the ```vagrant up``` invocations above.
- If you are using one of the **VMware** hypervisors you'll need to **[buy](http://www.vagrantup.com/vmware)** the matching Vagrant provider. After that and depending on your case, just add either ```--provider vmware-fusion``` or ```--provider vmware-workstation``` to the ```vagrant up``` invocations above.

## Customization

All aspects of your cluster setup can be customized with environment variables. Right now the available ones are:

 - **NUM_INSTANCES** will set the number of nodes (minions).

   > If unset defaults to 2
 - **UPDATE_CHANNEL** will set the default CoreOS channel to be used in the VMs.

   > The default is the **alpha** channel (alternatives would be **stable** and **beta**).

   > Please do note that as Kubernetes is a fastly evolving technology **CoreOS _alpha_
   > channel is the only one expected to behave reliably**. While, by convenience, we allow
   > one to invoke the _beta_ or _stable_ channels please be aware that your mileage
   > when consuming them may vary a whole lot.
   >
   > So, **before submitting a bug**, in [this](https://github.com/pires/kubernetes-vagrant-coreos-cluster/issues) project,
   > or upstream (either [Kubernetes](https://github.com/GoogleCloudPlatform/kubernetes/issues)
   > or [CoreOS](https://github.com/coreos/bugs/issues))
   > please **make sure it** (also) **happens in the** (default) **_alpha_ channel** :smile:
   >
 - **COREOS_VERSION** will set the specific CoreOS release (from the given channel) to be used.

   > The default is to use whatever is the latest one from the given channel.
 - **SERIAL_LOGGING** if set to true will allow logging from the VMs serial console.

   > It defaults to false. Only allow it if you *really* know what you are doing.
 - **MASTER_MEM** sets the master's VM memory.

   > Defaults to 512 (in MB)
 - **MASTER_CPUS** sets the number os vCPUs to be used by the master's VM.

   > Defaults to 1.
 - **NODE_MEM** sets the worker nodes' (aka minions in Kubernetes lingo) VM memory.

   > Defaults to 1024 (in MB)
 - **NODE_CPUS** sets the number os vCPUs to be used by the minions's VMs.

    > Defaults to 1.
 - **KUBERNETES_VERSION** defines the specific kubernetes version being used.

   > *If* the [world](http://google.com/about) was perfect we'd be using by default the latest and
   > greatest one, as it [isn't](https://github.com/GoogleCloudPlatform/kubernetes/issues/4415)
   > currently we are defaulting to 0.9.3.



So, in order to start, say, a Kubernetes cluster with 3 minion nodes, 2GB of RAM and 2 vCPUs per node one just would do...

```
NODE_MEM=2048 NODE_CPUS=2 NUM_INSTANCES=3 vagrant up
```

## Usage

You're now ready to use your Kubernetes cluster.

If you just want to test something simple, start with [Kubernetes examples](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).

## Licensing

This work is [open source](http://opensource.org/osd), and is licensed under the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
