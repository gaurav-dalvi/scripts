
# Contiv Troubleshooting Document

## Information about this installation

In this installation, we will be installing following components using ansible 2.2.0.0

1: netplugin and netmaster - `v0.1-12-23-2016.19-44-42.UTC`
```
netplugin --version or netmaster --version will give you version of each component running in
this setup
```

2: etcd - 2.3.1

3: Docker Swarm - 1.2.5

4: OpenVSwitch - 2.3.1-2.el7

5: Docker Engine - 1.12


## Troubleshooting Techniques:

#### Make sure you have passwordless SSH setup.

To setup passwordless SSH, please use this : http://twincreations.co.uk/pre-shared-keys-for-ssh-login-without-password/

If you have 3 nodes, Node1 Node2 and Node3 then please make sure you can do passwordless SSH from

Node1 to Node1

Node1 to Node2

Node1 to Node3

#### Make sure your etcd cluster is healthy

```
sudo etcdctl cluster-health
member 903d536c85a35515 is healthy: got healthy result from http://10.193.231.222:2379
member fa77f6921bc496d6 is healthy: got healthy result from http://10.193.231.245:2379
cluster is healthy

```

#### Make sure your docker swarm cluster is healthy

When you do run `docker info` command, You should be able to see

all the nodes which are your cluster right now.

For example, Sample o/p of docker ps command.
```
docker info
Containers: 8
 Running: 8
 Paused: 0
 Stopped: 0
Images: 12
Server Version: swarm/1.2.0
Role: replica
Primary: 10.193.231.245:2375
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 2
 localhost: 10.193.231.222:2385
  └ Status: Healthy
  └ Containers: 4
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 10.09 GiB
  └ Labels: executiondriver=, kernelversion=3.10.0-514.2.2.el7.x86_64, operatingsystem=CentOS Linux 7 (Core), storagedriver=devicemapper
  └ Error: (none)
  └ UpdatedAt: 2016-12-25T06:39:35Z
  └ ServerVersion: 1.11.1
 netmaster: 10.193.231.245:2385
  └ Status: Healthy
  └ Containers: 4
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 10.09 GiB
  └ Labels: executiondriver=, kernelversion=3.10.0-514.2.2.el7.x86_64, operatingsystem=CentOS Linux 7 (Core), storagedriver=devicemapper
  └ Error: (none)
  └ UpdatedAt: 2016-12-25T06:39:44Z
  └ ServerVersion: 1.11.1
Plugins:
 Volume:
 Network:
Kernel Version: 3.10.0-514.2.2.el7.x86_64
Operating System: linux
Architecture: amd64
CPUs: 2
Total Memory: 20.18 GiB
Name: 95720f4214ca
Docker Root Dir:
Debug mode (client): false
Debug mode (server): false
WARNING: No kernel memory limit support
```

#### Netmaster error :

If you see soemthing like this 

```
TASK [contiv_network : wait for netmaster to be ready] *************************
FAILED - RETRYING: TASK: contiv_network : wait for netmaster to be ready (9 retries left).
FAILED - RETRYING: TASK: contiv_network : wait for netmaster to be ready (9 retries left).
FAILED - RETRYING: TASK: contiv_network : wait for netmaster to be ready (8 retries left).
FAILED - RETRYING: TASK: contiv_network : wait for netmaster to be ready (8 retries left).
```
Please make sure you cleanup everything and try running script again

Cleanup Commands:

```
sudo ovs-vsctl del-br contivVxlanBridge
sudo ovs-vsctl del-br contivVlanBridge
for p in `ifconfig  | grep vport | awk '{print $1}'`; do sudo ip link delete $p type veth; done
sudo rm /var/run/docker/plugins/netplugin.sock
sudo etcdctl rm --recursive /contiv
sudo etcdctl rm --recursive /contiv.io
sudo etcdctl rm --recursive /skydns
sudo etcdctl rm --recursive /docker
curl -X DELETE localhost:8500/v1/kv/contiv.io?recurse=true
curl -X DELETE localhost:8500/v1/kv/docker?recurse=true

-- Uninstall Docker

sudo yum -y remove docker-engine.x86_64
sudo yum -y remove docker-engine-selinux.noarch

sudo rm -rf /var/lib/docker
if above commnd does not execute, please reboot machine and try again

-- Uninstall etcd

sudo rm -rf /usr/bin/etcd*
sudo rm -rf /var/lib/etcd*

```


#### Check ansible version

If you see any error realted to ansible, Please make sure that you are using right version of ansible.

```
ansible --version
ansible 2.2.0.0
  config file = /home/admin/.ansible.cfg
  configured module search path = Default w/o overrides
```

#### Regarding cfg.yml

Please make sure that you have correct data and control interfaces entered in cfg.yml file.
Also please verify APIC details as well.

#### Regarding topology of ACI:

You can give ACI topology information to contiv in following manner.

```
APIC_LEAF_NODES:
    - topology/pod-1/node-101
    - topology/pod-1/node-102
    - topology/pod-1/paths-101/pathep-[eth1/14]
    
```

#### Correct version of aci-gw container:

Make sure that you are using correct aci-gw version.

```
If you are using APIC 2.1_1h, then you should be using

contiv/aci-gw:12-01-2016.2.1_1h

otherwise please use

contiv/aci-gw:latest (By default script will use this)

docker ps command will show you the version of aci-gw which you are running on nodes in your cluster.

```

