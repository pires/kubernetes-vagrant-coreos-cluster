# kubernetes-vagrant-coreos-cluster
Kubernetes (0.9.3) cluster made easy with Vagrant (1.7.2+) and CoreOS alpha (591.0.0).
If you want to run the latest release available, please proceed with cloud-config files located in ```/latest```.

## Pre-requisites

 * Virtualbox or Parallels Desktop
 * Vagrant
 * ```kubectl```
 * ```fleetctl``` (optional for debugging Fleet)
 * ```etcdctl``` (optional for debugging Etcd)

### fleetctl, etcdctl, kubectl

On Mac OS, do, in advance
```
brew install wget fleetctl etcdctl
```

Then run ```./kubLocalInstall install``` to download 'kubectl' binary (into /usr/local/bin which should be already in your default $PATH). You can also install a specific kubectl version via the KUBERNETES_VERSION environment variable.

Finally, just run ```$(./kubLocalInstall shellinit)``` to set all needed environment variables for you, on your running shell.

## Master

Current ```Vagrantfile``` will bootstrap one VM with everything needed to become a Kubernetes master.
```
vagrant up master
```

Verify ```fleet``` sees it
```
fleetctl list-machines
```

You should see something like
```
MACHINE		IP		METADATA
dd0ee115...	172.17.8.101	role=master
```

## Minions

Current ```Vagrantfile``` will bootstrap two VMs with everything needed to have two Kubernetes minions. You can change this by editing ```Vagrantfile```.

```
vagrant up node-01
vagrant up node-02
```

Verify ```fleet``` again, just for the sake of it
```
fleetctl list-machines
```

You should see something like
```
MACHINE		IP		METADATA
dd0ee115...	172.17.8.101	role=master
74a8dc8c...	172.17.8.102	role=kubernetes
c93da9ff...	172.17.8.103    role=kubernetes
```

## Parallels Desktop support

If you are using Parallels Desktop and the [vagrant-parallels](http://parallels.github.io/vagrant-parallels/docs/) provider
just add ```--provider parallels``` to the ```vagrant up``` invocations above

## Customization

All aspects of your cluster setup can be customized with environment variables. right now the available ones are:

 - **NUM_INSTANCES** will set the number of nodes (minions).
   If unset defaults to 2
 - **UPDATE_CHANNEL** will set the default CoreOS channel to be used in the VMs.
   The default is the **alpha** channel (alternatives are **stable** and **beta**).
 - **COREOS_VERSION** will set the specific CoreOS release (from the set channel) to be used.
   The default is to use whatever is the latest one from the given channel.
 - **SERIAL_LOGGING** if set to true will allow logging from the VMs serial console.
   It defaults to false. Only allow it if you *really* know what you are doing.
 - **MASTER_MEM** sets the master's VM memory. Defaults to 512 (MB)
 - **MASTER_CPUS** sets the number os vCPUs to be used by the master's VM. Defaults to 1.
 - **NODE_MEM** sets the minions's VM memory. Defaults to 1024 (MB)
 - **NODE_CPUS** sets the number os vCPUs to be used by the minions's VMs. Defaults to 1.
 - **KUBERNETES_VERSION** defines the specific kubernetes version being used.
 *If* the [world](http://google.com/about) was perfect we'd be using by default the latest and
 greatest one, as it [isn't](https://github.com/GoogleCloudPlatform/kubernetes/issues/4415)
 currently we are defaulting to 0.9.3.

So, in order to start, say, a cluster based on CoreOS's stable channel one just would do...

```
UPDATE_CHANNEL=stable vagrant up
```

## Usage

You're now ready to use your Kubernetes cluster.

If you just want to test something simple, start with [Kubernetes examples](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).

## Licensing

This work is [open source](http://opensource.org/osd), and is licensed under the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
