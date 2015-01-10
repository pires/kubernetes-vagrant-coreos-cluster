# kubernetes-vagrant-coreos-cluster
Kubernetes (0.8.0) cluster made easy with Vagrant (1.7.2+) and CoreOS.

## Pre-requisites
 
 * Virtualbox
 * Vagrant
 * ```kubectl```
 * ```fleetctl``` (optional for debugging Fleet)
 * ```etcdctl``` (optional for debugging Etcd)

### fleetctl, etcdctl

On Mac OS
```
brew install wget fleetctl etcdctl
export ETCDCTL_PEERS=http://172.17.8.101:4001
export FLEETCTL_ENDPOINT=http://172.17.8.101:4001
```

### kubectl

On Mac OS
```
cd /opt
sudo wget -c https://github.com/GoogleCloudPlatform/kubernetes/releases/download/v0.8.0/kubernetes.tar.gz
sudo tar zxf kubernetes.tar.gz
export PATH=/opt/kubernetes/platforms/darwin/amd64:$PATH
export KUBERNETES_MASTER=http://172.17.8.101:8080
```

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

## Usage

You're now ready to use your Kubernetes cluster.

If you just want to test something simple, start with [Kubernetes examples](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).
