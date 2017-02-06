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

### 1: Make sure you have passwordless SSH setup.

To setup passwordless SSH, please use this : http://twincreations.co.uk/pre-shared-keys-for-ssh-login-without-password/

If you have 3 nodes, Node1 Node2 and Node3 then please make sure you can do passwordless SSH from

Node1 to Node1

Node1 to Node2

Node1 to Node3

### 2: Make sure your etcd cluster is healthy

```
sudo etcdctl cluster-health
member 903d536c85a35515 is healthy: got healthy result from http://10.193.231.222:2379
member fa77f6921bc496d6 is healthy: got healthy result from http://10.193.231.245:2379
cluster is healthy

```

### 3: Make sure your docker swarm cluster is healthy

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

### 4: Netmaster error :

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

-- Docker Cleanup Steps
sudo docker kill -s 9 $(sudo docker ps -q)
sudo docker rm -fv $(sudo docker ps -a -q)
sudo systemctl stop docker
for i in $(mount | grep docker | awk '{ print $3 }'); do sudo umount $i || true; done
sudo umount /var/lib/docker/devicemapper || true
sudo yum -y remove docker-engine.x86_64
sudo yum -y remove docker-engine-selinux.noarch
sudo rm -rf /var/lib/docker
if above commnd does not execute, please reboot machine and try again

-- Uninstall etcd

sudo systemctl stop etcd
sudo rm -rf /usr/bin/etcd*
sudo rm -rf /var/lib/etcd*

```

### 5: Regarding cfg.yml

Please make sure that you have correct data and control interfaces entered in cfg.yml file.
Also please verify APIC details as well.

### 6: Regarding topology of ACI:

You can give ACI topology information to contiv in following manner.

```
APIC_LEAF_NODES:
    - topology/pod-1/node-101
    - topology/pod-1/node-102
    - topology/pod-1/paths-101/pathep-[eth1/14]
    
```

### 7: Correct version of aci-gw container:

Make sure that you are using correct aci-gw version.

```
If you are using APIC 2.1_1h, then you should be using

contiv/aci-gw:12-01-2016.2.1_1h

otherwise please use

contiv/aci-gw:latest (By default script will use this)

docker ps command will show you the version of aci-gw which you are running on nodes in your cluster.

```

### 8: Troubleshooting Datapath of Contiv:

To find container ID from name of the container

```
Creating container:
docker run -itd --net="n1/t1" --name=testContainer alpine sh

Finding ID of container:
docker ps | grep test
6e329f08fbf0        alpine              "sh"                     28 seconds ago      Up 26 seconds                                test

```

Find endpoint ID using netctl command:

```
netctl endpoint inspect 6e329f08fbf0
Inspecting endpoint: 6e329f08fbf0
{
  "Oper": {
    "containerID": "6e329f08fbf0646ab7952e360ba9e36a4900bea31b665a1d6c0b9b6373eb4476",
    "containerName": "/test",
    "endpointGroupId": 1,
    "endpointGroupKey": "g1:t1",
    "endpointID": "dc6ddf624ffd68f234806403e66b1afc24009fa4f8a182a7a2f617820451537b",
    "homingHost": "netplugin-node1",
    "ipAddress": [
      "20.1.1.1",
      ""
    ],
    "labels": "map[]",
    "macAddress": "02:02:14:01:01:01",
    "network": "n1.t1",
    "serviceName": "g1"
  }
}
[vagrant@netplugin-node1 netplugin]$ netctl endpoint inspect 6e329f08fbf0 | grep endpointID
    "endpointID": "dc6ddf624ffd68f234806403e66b1afc24009fa4f8a182a7a2f617820451537b",
```

Find Name of veth port by matching the endpointID

```
sudo ovs-vsctl list interface | grep -A 14 dc6ddf624ffd68f234806403e66b1afc24009fa4f8a182a7a2f617820451537b | grep name
name                : "vvport1"

```

Dump the flow entries in OVS

```
sudo ovs-ofctl -O Openflow13 dump-flows contivVlanBridge
OFPST_FLOW reply (OF1.3) (xid=0x2):
 cookie=0x1e, duration=529.057s, table=0, n_packets=0, n_bytes=0, priority=101,udp,dl_vlan=4093,dl_src=02:02:00:00:00:00/ff:ff:00:00:00:00,tp_dst=53 actions=pop_vlan,goto_table:1
 cookie=0x1c, duration=529.057s, table=0, n_packets=0, n_bytes=0, priority=100,arp,arp_op=1 actions=CONTROLLER:65535
 cookie=0x22, duration=528.031s, table=0, n_packets=0, n_bytes=0, priority=102,udp,in_port=2,tp_dst=53 actions=goto_table:1
 cookie=0x20, duration=528.031s, table=0, n_packets=0, n_bytes=0, priority=102,udp,in_port=1,tp_dst=53 actions=goto_table:1
 cookie=0x1a, duration=529.057s, table=0, n_packets=2102, n_bytes=260304, priority=1 actions=goto_table:1
 cookie=0x1d, duration=529.057s, table=0, n_packets=0, n_bytes=0, priority=100,udp,dl_src=02:02:00:00:00:00/ff:ff:00:00:00:00,tp_dst=53 actions=CONTROLLER:65535
 cookie=0x1b, duration=529.057s, table=1, n_packets=0, n_bytes=0, priority=1 actions=goto_table:3
 cookie=0x2d, duration=172.804s, table=1, n_packets=8, n_bytes=648, priority=10,in_port=3 actions=write_metadata:0x100010000/0xff7fff0000,goto_table:2
 cookie=0x21, duration=528.031s, table=1, n_packets=0, n_bytes=0, priority=100,in_port=1 actions=goto_table:5
 cookie=0x23, duration=528.031s, table=1, n_packets=0, n_bytes=0, priority=100,in_port=2 actions=goto_table:5
 cookie=0x19, duration=529.057s, table=2, n_packets=8, n_bytes=648, priority=1 actions=goto_table:3
 cookie=0x17, duration=529.058s, table=3, n_packets=8, n_bytes=648, priority=1 actions=goto_table:4
 cookie=0x2e, duration=172.804s, table=3, n_packets=0, n_bytes=0, priority=100,ip,metadata=0x100000000/0xff00000000,nw_dst=20.1.1.1 actions=write_metadata:0x2/0xfffe,goto_table:4
 cookie=0x18, duration=529.057s, table=4, n_packets=8, n_bytes=648, priority=1 actions=goto_table:5
 cookie=0x16, duration=529.058s, table=5, n_packets=8, n_bytes=648, priority=1 actions=goto_table:7
 cookie=0x1f, duration=529.057s, table=7, n_packets=8, n_bytes=648, priority=1 actions=NORMAL

```

To find uplink ports :

```
sudo ovs-vsctl  list interface | grep name | grep "eth[0-9]"
name                : "eth2"
name                : "eth3"
```

### 9: ACI Ping problem:

If you see ping is not working in ACI environment, check if eth1 is enabled or not.
```
ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:50:56:0c:02:27 brd ff:ff:ff:ff:ff:ff
    inet 10.0.236.75/24 brd 10.0.236.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::250:56ff:fe0c:227/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:50:56:8c:7f:04 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::e9dd:85af:62b3:370f/64 scope link 
       valid_lft forever preferred_lft forever
```

also please check this- if eth1 is down you should see something like this in the log.

```
grep "No active interface on uplink. Not reinjecting ARP request pkt" /var/log/messages
```
