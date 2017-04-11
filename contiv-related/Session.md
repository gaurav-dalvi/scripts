
## Containers Networking Tutorial with Contiv
This tutorial walks you through container networking and concepts step by step. We will also explore Contiv's networking features along with policies.


### Setup

**Note**:
- Please make sure that you are logged on `Installer-Host machine`, for follwoing steps.

#### Step 1: Get contiv installer from github. 


```
cd ~
wget https://github.com/contiv/install/releases/download/1.0.0-beta.6/contiv-1.0.0-beta.6.tgz
tar -zxvf contiv-1.0.0-beta.6.tgz

```

#### Step 2: Setup passwordless SSH among these 3 nodes.

```
mkdir .ssh && chmod 700 .ssh

ssh-keygen -t rsa -f ~/.ssh/id_rsa  -N ""

sshpass -p cisco.123 ssh-copy-id -i ~/.ssh/id_rsa.pub root@pod07-srv1.ecatsrtpdmz.cisco.com -o StrictHostKeyChecking=no

sshpass -p cisco.123 ssh-copy-id -i ~/.ssh/id_rsa.pub root@pod07-srv2.ecatsrtpdmz.cisco.com -o StrictHostKeyChecking=no

```

#### Step 3: Create config file to install contiv

```
cat << EOF > ~/cfg.yml
CONNECTION_INFO:
      pod07-srv1.ecatsrtpdmz.cisco.com:
        role: master
        control: eth0
        data: eth1
      pod07-srv2.ecatsrtpdmz.cisco.com:
        control: eth0
        data: eth1

EOF

```

#### Step 4: Install contiv on pod07-srv1 and pod07-srv2

```
cd ~/contiv-1.0.0-beta.6

./install/ansible/install_swarm.sh -f ~/cfg.yml -e ~/.ssh/id_rsa -u root -i

```

Some examples of installer:

```
Examples:
1. Uninstall Contiv and Docker Swarm on hosts specified by cfg.yml.
./install/ansible/uninstall_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i
2. Uninstall Contiv and Docker Swarm on hosts specified by cfg.yml for an ACI setup.
./install/ansible/uninstall_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i -m aci
3. Uninstall Contiv and Docker Swarm on hosts specified by cfg.yml for an ACI setup, remove all containers and Contiv etcd state
./install/ansible/uninstall_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i -m aci -r

```

**Note**:
- For next set of steps, We will be logging in on pod07-srv1 and pod07-srv2


#### Step 4: Hello world Docker swarm.

As a part of this contiv installation, we install docker swarm for you. 

To verify docker swarm cluster, let us perform following steps.
**Note**:
- Make sure you execute following steps on pod07-srv1 as well as pod07-srv2


```
export DOCKER_HOST=tcp://pod07-srv1.ecatsrtpdmz.cisco.com:2375

cd ~
sed -i -e '$a export DOCKER_HOST=tcp://pod07-srv1.ecatsrtpdmz.cisco.com:2375' .bashrc
cat .bashrc

```

Now verify that swarm is running successfully or not.

```
docker info

```

Docker swarm with 2 nodes is running successfully.

Scheduler schedules these containers using the
scheduling algorithm `bin-packing` or `spread`, and if they are not placed on 
different nodes, feel free to start more containers to see the distribution.

#### Step 5: Check contiv and related services.

`etcdctl` is a control utility to manipulate etcd, state store used by kubernetes/docker/contiv

To check etcd cluster health

```
etcdctl cluster-health

```

To check netplugin and netmaster is running successfully.

```
sudo service netmaster status

sudo service netplugin status

```

`netctl` is a utility to create, update, read and modify contiv objects. It is a CLI wrapper
on top of REST interface.


```
netctl version
Client Version:
Version: 1.0.0-beta.4
GitCommit: fe95411
BuildTime: 03-23-2017.18-47-57.UTC

Server Version:
Version: 1.0.0-beta.4
GitCommit: fe95411
BuildTime: 03-23-2017.18-47-57.UTC

```
--------------------------------------------------------------------------------------------

```
[vagrant@contiv-node3 ~]$ ifconfig docker0
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        ether 02:42:72:6c:8d:f7  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[vagrant@contiv-node3 ~]$ ifconfig eth1
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.2.52  netmask 255.255.255.0  broadcast 192.168.2.255
        inet6 fe80::a00:27ff:feb6:8af9  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:b6:8a:f9  txqueuelen 1000  (Ethernet)
        RX packets 17210  bytes 8681707 (8.2 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 9908  bytes 2438902 (2.3 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[vagrant@contiv-node3 ~]$ ifconfig eth0
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::5054:ff:fe1f:dbb7  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:1f:db:b7  txqueuelen 1000  (Ethernet)
        RX packets 203696  bytes 186767867 (178.1 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 77560  bytes 4354377 (4.1 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```


In the above output, you'll see:
- `docker0` interface corresponds to the linux bridge and its associated
subnet `172.17.0.1/16`. This is created by docker daemon automatically, and
is the default network containers would belong to when an override network
is not specified
- `eth0` in this VM is the management interface, on which we ssh into the VM
- `eth1` in this VM is the interface that connects to external network (if needed)
- `eth2` in this VM is the interface that carries vxlan and control (e.g. etcd) traffic


### Chapter 1 - Introduction to Container Networking

There are two main container networking model discussed within the community.

#### Docker libnetwork - Container Network Model (CNM)

CNM (Container Network Model) is Docker's libnetwork network model for containers
- An endpoint is container's interface into a network
- A network is collection of arbitrary endpoints
- A container can belong to multiple endpoints (and therefore multiple networks)
- CNM allows for co-existence of multiple drivers, with a network managed by one driver
- Provides Driver APIs for IPAM and Endpoint creation/deletion
- IPAM Driver APIs: Create/Delete Pool, Allocate/Free IP Address
- Network Driver APIs: Network Create/Delete, Endpoint Create/Delete/Join/Leave
- Used by docker engine, docker swarm, and docker compose; and other schedulers
that schedules regular docker containers e.g. Nomad or Mesos docker containerizer

#### CoreOS CNI - Container Network Interface (CNI)
CNI (Container Network Interface) CoreOS's network model for containers
- Allows container id (uuid) specification for the network interface you create
- Provides Container Create/Delete events
- Provides access to network namespace to the driver to plumb networking
- No separate IPAM Driver: Container Create returns the IAPM information along with other data
- Used by Kubernetes and thus supported by various Kubernetes network plugins, including Contiv

Using Contiv with CNI/Kubernetes can be found [here](https://github.com/contiv/netplugin/tree/master/mgmtfn/k8splugin).
The rest of the tutorial walks through the docker examples, which implements CNM APIs

#### Basic container networking

Let's examine the networking a container gets upon vanilla run

```
[vagrant@contiv-node3 ~]$ docker network ls
NETWORK ID          NAME                  DRIVER              SCOPE
a1729504b2d1        contiv-node3/bridge   bridge              local
422bc594582f        contiv-node3/host     host                local
5d6b06097745        contiv-node3/none     null                local
7dc18de21668        contiv-node4/bridge   bridge              local
72680804a591        contiv-node4/host     host                local
18b816723b79        contiv-node4/none     null                local

[vagrant@contiv-node3 ~]$ docker run -itd --name=vanilla-c alpine /bin/sh
58d5fe78d517834b0172b7ca90521e058680cf3de1fc7824cf66a097c1cffc11

**Note**:
- Please note this container got scheduled by docker swarm on contiv-node4. 
Run `docker ps` and check NAMES column to find it.

**
[vagrant@contiv-node3 ~]$ ifconfig 
```

In the `ifconfig` output, you will see that it would have created a veth `virtual 
ethernet interface` that could look like `veth......` towards the end. More 
importantly it is allocated an IP address from default docker bridge `docker0`, 
likely `172.17.0.5` in this setup, and can be examined using

```
[vagrant@contiv-node3 ~]$ docker network inspect contiv-node4/bridge
[
    {
        "Name": "bridge",
        "Id": "7dc18de21668de453dd696de5a130b59c3afe7d79dfca2ed10b3919f12474eff",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16"
                }
            ]
        },
        "Internal": false,
        "Containers": {
            "58d5fe78d517834b0172b7ca90521e058680cf3de1fc7824cf66a097c1cffc11": {
                "Name": "vanilla-c",
                "EndpointID": "f0feb63de2465891fe8b2f94141b79b47865e9f048f395b1c323555a5314b3f8",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]

[vagrant@contiv-node3 ~]$ docker inspect --format '{{.NetworkSettings.IPAddress}}' vanilla-c
172.17.0.2
```

The other pair of veth interface is put into the container with the name `eth0`

```
[vagrant@contiv-node3 ~]$ docker inspect --format '{{.NetworkSettings.IPAddress}}' vanilla-c
172.17.0.2
[vagrant@contiv-node3 ~]$ docker exec -it vanilla-c /bin/sh
/ # ifconfig eth0
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02
          inet addr:172.17.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe11:2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1296 (1.2 KiB)  TX bytes:648 (648.0 B)
/ # exit
```

All traffic to/from this container is Port-NATed to the host's IP (on eth0).
The Port NATing on the host is done using iptables, which can be seen as a
MASQUERADE rule for outbound traffic for `172.17.0.0/16`

```
[vagrant@contiv-node3 ~]$ sudo iptables -t nat -L -n
```

### Chapter 2: Multi-host networking

There are many solutions like Contiv such as Calico, Weave, OpenShift, OpenContrail, Nuage,
VMWare, Docker, Kubernetes, OpenStack that provide solutions to multi-host
container networking. 

In this section, let's examine Contiv and Docker overlay solutions.

#### Multi-host networking with Contiv
Let's use the same example as above to spin up two containers on the two different hosts

#### 1. Create a multi-host network

```
[vagrant@contiv-node3 ~]$ netctl net create --subnet=10.1.2.0/24 contiv-net
[vagrant@contiv-node3 ~]$ netctl net ls
Tenant   Network     Nw Type  Encap type  Packet tag  Subnet       Gateway
------   -------     -------  ----------  ----------  -------      ------
default  contiv-net  data     vxlan       0           10.1.2.0/24  

[vagrant@contiv-node3 ~]$ docker network ls
NETWORK ID          NAME                  DRIVER              SCOPE
c7b8c135c9f1        contiv-net            netplugin           global
a1729504b2d1        contiv-node3/bridge   bridge              local
422bc594582f        contiv-node3/host     host                local
5d6b06097745        contiv-node3/none     null                local
7dc18de21668        contiv-node4/bridge   bridge              local
72680804a591        contiv-node4/host     host                local
18b816723b79        contiv-node4/none     null                local   

[vagrant@contiv-node3 ~]$ docker network inspect contiv-net
[
    {
        "Name": "contiv-net",
        "Id": "c7b8c135c9f1b94614db84875b95873c833af56b2aac0606a88d2497ccb2a055",
        "Scope": "global",
        "Driver": "netplugin",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "netplugin",
            "Options": {
                "network": "contiv-net",
                "tenant": "default"
            },
            "Config": [
                {
                    "Subnet": "10.1.2.0/24"
                }
            ]
        },
        "Internal": false,
        "Containers": {},
        "Options": {
            "encap": "vxlan",
            "pkt-tag": "1",
            "tenant": "default"
        },
        "Labels": {}
    }
]
```

You can now run a new container belonging to `contiv-net` network:

```
[vagrant@contiv-node3 ~]$ docker run -itd --name=contiv-c1 --net=contiv-net alpine /bin/sh
09689c15f6410c049e16d60cfe42926009af163aeb4296569cb17869a5b69732
```

Let's ssh into the second node using 

```
cd cluster
vagrant ssh contiv-node4
[vagrant@contiv-node4 ~]$ export DOCKER_HOST=tcp://192.168.2.52:2375

``` 

and spin up a new container on it and try to reach container running on the other host.


```
docker run -itd --name=contiv-c2 --net=contiv-net alpine /bin/sh
f09a78e7960d6c1dfbf86e85648c44479681ef22a86e3049dc2296178ece9c7f
[vagrant@contiv-node4 ~]$ docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS              PORTS               NAMES
f09a78e7960d        alpine                           "/bin/sh"                3 seconds ago       Up 1 seconds                            contiv-node3/contiv-c2
09689c15f641        alpine                           "/bin/sh"                3 minutes ago       Up 3 minutes                            contiv-node4/contiv-c1

[vagrant@contiv-node4 ~]$ docker exec -it contiv-c2 /bin/sh
/ #
/ # ping contiv-c1
PING contiv-c1 (10.1.2.1): 56 data bytes
64 bytes from 10.1.2.1: seq=0 ttl=64 time=4.236 ms
64 bytes from 10.1.2.1: seq=1 ttl=64 time=0.941 ms
^C
--- contiv-c1 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.941/2.588/4.236 ms
/ # exit
```

As you will see during the ping that, built in dns resolves the name `contiv-c1`
to the IP address of `contiv-c1` container and be able to reach another container
across using a vxlan overlay.


#### Docker Overlay multi-host networking

Docker engine has a built in overlay driver that can be use to connect
containers across multiple nodes. However since vxlan port used by `contiv`
driver is same as that of `overlay` driver from Docker, we will use
Docker's overlay multi-host networking towards the end after we experiment
with `contiv` because then we can terminate the contiv driver and
let Docker overlay driver use the vxlan port bindings. More about it in
later chapter.

### Chapter 3: Using multiple tenants with arbitrary IPs in the networks

First, let's create a new tenant space. Also ssh into contiv-node3 node and export DOCKER_HOST with correct value.

```
[vagrant@contiv-node3 ~]$ netctl tenant create blue
Creating tenant: blue                  

[vagrant@contiv-node3 ~]$ netctl tenant ls
Name
------
default
blue
```

After the tenant is created, we can create network within in tenant `blue` and run containers.
Here we chose the same subnet and network name for it.
the same subnet and same network name, that we used before

```
[vagrant@contiv-node3 ~]$ netctl net create -t blue --subnet=10.1.2.0/24 contiv-net
Creating network blue:contiv-net
[vagrant@contiv-node3 ~]$ netctl net ls -t blue
Tenant  Network     Nw Type  Encap type  Packet tag  Subnet       Gateway  IPv6Subnet  IPv6Gateway
------  -------     -------  ----------  ----------  -------      ------   ----------  -----------
blue    contiv-net  data     vxlan       0           10.1.2.0/24
```

Next, we can run containers belonging to this tenant

```
[vagrant@contiv-node3 ~]$ docker run -itd --name=contiv-blue-c1 --net="contiv-net/blue" alpine /bin/sh
224be352b574493336e8570b8925a359f808fc05f98b791ca5b14ec9ed580339

[vagrant@contiv-node3 ~]$ docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS              PORTS               NAMES
224be352b574        alpine                           "/bin/sh"                12 seconds ago      Up 11 seconds                           contiv-node4/contiv-blue-c1
f09a78e7960d        alpine                           "/bin/sh"                5 minutes ago       Up 5 minutes                            contiv-node3/contiv-c2
09689c15f641        alpine                           "/bin/sh"                8 minutes ago       Up 8 minutes                            contiv-node4/contiv-c1
58d5fe78d517        alpine                           "/bin/sh"                43 minutes ago      Up 43 minutes                           contiv-node4/vanilla-c
8e08d18caf2c        contiv/auth_proxy:1.0.0-beta.4   "./auth_proxy --tls-k"   58 minutes ago      Up 58 minutes                           contiv-node3/auth-proxy
77943d7f8a84        quay.io/coreos/etcd:v2.3.8       "/etcd"                  About an hour ago   Up About an hour                        contiv-node4/etcd
1a266627540f        quay.io/coreos/etcd:v2.3.8       "/etcd"                  About an hour ago   Up About an hour                        contiv-node3/etcd
```

Let us run a couple of more containers in the host `contiv-node4` that belong to the tenant `blue`:

(Dont forget to set DOCKER_HOST variable after you ssh into this node)

```
[vagrant@contiv-node4 ~]$ docker run -itd --name=contiv-blue-c2 --net="contiv-net/blue" alpine /bin/sh
be63dbd230d6062a07ba63e0ec1af047d4a1181b4003b64a1e5b42ab019c1f43
[vagrant@contiv-node4 ~]$ docker run -itd --name=contiv-blue-c3 --net="contiv-net/blue" alpine /bin/sh
1db8d18a88fe976f007e49bcb68e4e7d10ff0d08a2f7ff2ef3e3ac2b00cccc52
[vagrant@contiv-node4 ~]$ docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS              PORTS               NAMES
1db8d18a88fe        alpine                           "/bin/sh"                15 seconds ago      Up 14 seconds                           contiv-node4/contiv-blue-c3
be63dbd230d6        alpine                           "/bin/sh"                58 seconds ago      Up 56 seconds                           contiv-node3/contiv-blue-c2
224be352b574        alpine                           "/bin/sh"                2 minutes ago       Up 2 minutes                            contiv-node4/contiv-blue-c1
f09a78e7960d        alpine                           "/bin/sh"                8 minutes ago       Up 7 minutes                            contiv-node3/contiv-c2
09689c15f641        alpine                           "/bin/sh"                11 minutes ago      Up 11 minutes                           contiv-node4/contiv-c1
58d5fe78d517        alpine                           "/bin/sh"                45 minutes ago      Up 45 minutes                           contiv-node4/vanilla-c
8e08d18caf2c        contiv/auth_proxy:1.0.0-beta.4   "./auth_proxy --tls-k"   About an hour ago   Up About an hour                        contiv-node3/auth-proxy
77943d7f8a84        quay.io/coreos/etcd:v2.3.8       "/etcd"                  About an hour ago   Up About an hour                        contiv-node4/etcd
1a266627540f        quay.io/coreos/etcd:v2.3.8       "/etcd"                  About an hour ago   Up About an hour                        contiv-node3/etcd

[vagrant@contiv-node4 ~]$ docker network inspect contiv-net/blue
[
    {
        "Name": "contiv-net/blue",
        "Id": "cf4c34e778b7a587c8c7726a59aef3313f6ee8ebf0e3a318f320ce259387b3ad",
        "Scope": "global",
        "Driver": "netplugin",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "netplugin",
            "Options": {
                "network": "contiv-net",
                "tenant": "blue"
            },
            "Config": [
                {
                    "Subnet": "10.1.2.0/24"
                }
            ]
        },
        "Internal": false,
        "Containers": {
            "1db8d18a88fe976f007e49bcb68e4e7d10ff0d08a2f7ff2ef3e3ac2b00cccc52": {
                "Name": "contiv-blue-c3",
                "EndpointID": "c297a0479c9a18a5a69e04a4c53bc9aa5a78ecc103668c7aadf2ff62e21e0664",
                "MacAddress": "02:02:0a:01:02:03",
                "IPv4Address": "10.1.2.3/24",
                "IPv6Address": ""
            },
            "224be352b574493336e8570b8925a359f808fc05f98b791ca5b14ec9ed580339": {
                "Name": "contiv-blue-c1",
                "EndpointID": "fc5edc5de3548e063c2db2dfe14159d8c36e56f0cc8bdfed7585de4b45d8f72c",
                "MacAddress": "02:02:0a:01:02:01",
                "IPv4Address": "10.1.2.1/24",
                "IPv6Address": ""
            },
            "be63dbd230d6062a07ba63e0ec1af047d4a1181b4003b64a1e5b42ab019c1f43": {
                "Name": "contiv-blue-c2",
                "EndpointID": "3e4f4035386696187bc19894cc0fd8d730a97e59944a72c48d3a40f4ee210e00",
                "MacAddress": "02:02:0a:01:02:02",
                "IPv4Address": "10.1.2.2/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "encap": "vxlan",
            "pkt-tag": "2",
            "tenant": "blue"
        },
        "Labels": {}
    }
]

[vagrant@contiv-node4 ~]$ docker exec -it contiv-blue-c3 /bin/sh
/ # ping contiv-blue-c1
PING contiv-blue-c1 (10.1.2.1): 56 data bytes
64 bytes from 10.1.2.1: seq=0 ttl=64 time=1.105 ms
64 bytes from 10.1.2.1: seq=1 ttl=64 time=0.089 ms
64 bytes from 10.1.2.1: seq=2 ttl=64 time=0.106 ms
^C
--- contiv-blue-c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.089/0.433/1.105 ms
/ # ping contiv-blue-c2
PING contiv-blue-c2 (10.1.2.2): 56 data bytes
64 bytes from 10.1.2.2: seq=0 ttl=64 time=2.478 ms
64 bytes from 10.1.2.2: seq=1 ttl=64 time=1.054 ms
64 bytes from 10.1.2.2: seq=2 ttl=64 time=0.895 ms
^C
--- contiv-blue-c2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.895/1.475/2.478 ms

/ # exit
```

### Chapter 4: Connecting containers to external networks

In this chapter, we explore ways to connect containers to the external networks

#### 1. External Connectivity using Host NATing

Docker uses the linux bridge (docker_gwbridge) based PNAT to reach out and port mappings
for others to reach to the container

```
[vagrant@contiv-node4 ~]$ docker exec -it contiv-c1 /bin/sh
/ # ifconfig -a
eth0      Link encap:Ethernet  HWaddr 02:02:0A:01:02:01
          inet addr:10.1.2.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::2:aff:fe01:201/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:19 errors:0 dropped:0 overruns:0 frame:0
          TX packets:11 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1534 (1.4 KiB)  TX bytes:886 (886.0 B)

eth1      Link encap:Ethernet  HWaddr 02:42:AC:12:00:02
          inet addr:172.18.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe12:2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:31 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2466 (2.4 KiB)  TX bytes:648 (648.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

/ # ping contiv.com
PING contiv.com (216.239.32.21): 56 data bytes
64 bytes from 216.239.32.21: seq=0 ttl=61 time=33.051 ms
64 bytes from 216.239.32.21: seq=1 ttl=61 time=41.745 ms
^C
--- contiv.com ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 33.051/37.398/41.745 ms

/ # exit
```

What you see is that container has two interfaces belonging to it:
- eth0 is reachability into the `contiv-net` 
- eth1 is reachability for container to the external world and outside
traffic to be able to reach the container `contiv-c1`. This also relies on the host's dns
resolv.conf as a default way to resolve non container IP resolution.

Similarly outside traffic can be exposed on specific ports using `-p` command. Before
we do that, let us confirm that port 9099 is not reachable from the host
`contiv-node3`. To install `nc` netcat utility please run `sudo yum -y install nc and sudo yum install tcpdump` on contiv-node3

```
# Install nc utility

[vagrant@contiv-node3 ~]$ sudo yum -y install nc
< some yum install output >
Complete!

[vagrant@contiv-node3 ~]$ sudo yum install tcpdump
< some yum install output >
Complete!

[vagrant@contiv-node3 ~]$ nc -vw 1 localhost 9099
Ncat: Version 6.40 ( http://nmap.org/ncat )
Ncat: Connection refused.
```

Now we start a container that exposes tcp port 9099 out in the host.

```
[vagrant@contiv-node3 ~]$ docker run -itd -p 9099:9099 --name=contiv-exposed --net=contiv-net alpine /bin/sh
a36a8c3eda6675582d9c3f77b30dd50d8d9592bf20919f57d7b4e70ed8d8ff49
```

And if we re-run our `nc` utility, we'll see that 9099 is reachable.

```
[vagrant@contiv-node3 ~]$ nc -vw 1 localhost 9099
Ncat: Version 6.40 ( http://nmap.org/ncat )
Ncat: Connected to 127.0.0.1:9099.
^C
```

This happens because docker as soon as a port is exposed, a NAT rule is installed for
the port to allow rest of the network to access the container on the specified/exposed
port. The nat rules on the host can be seen by:

```
[vagrant@contiv-node3 ~]$ sudo iptables -t nat -L -n
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination
CONTIV-NODEPORT  all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0
MASQUERADE  all  --  172.19.0.0/16        0.0.0.0/0
MASQUERADE  tcp  --  172.18.0.4           172.18.0.4           tcp dpt:9099

Chain CONTIV-NODEPORT (1 references)
target     prot opt source               destination

Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9099 to:172.18.0.4:9099
```

#### 2. Natively connecting to the external networks

Remote drivers, like Contiv, can provide an easy way to connect to external
layer2 or layer3 networks using BGP or standard L2 access into the network.

Preferably using an BGP hand-off to the leaf/TOR, this can be done as in 
[http://contiv.github.io/documents/networking/bgp.html], which describes how
can you use BGP with Contiv to provide native container connectivity and 
reachability to rest of the network. However for this tutorial, since we don't
have a real or simulated BGP router, we'll use some very simple native L2
connectivity to describe the power of native connectivity. This is done 
using vlan network, for example

```
[vagrant@contiv-node3 ~]$ netctl net create -p 112 -e vlan -s 10.1.3.0/24 contiv-vlan
Creating network default:contiv-vlan
[vagrant@contiv-node3 ~]$ netctl net ls
Tenant   Network      Nw Type  Encap type  Packet tag  Subnet       Gateway  IPv6Subnet  IPv6Gateway
------   -------      -------  ----------  ----------  -------      ------   ----------  -----------
default  contiv-vlan  data     vlan        112         10.1.3.0/24
default  contiv-net   data     vxlan       0           10.1.2.0/24  
```

The allocated vlan can be used to connect any workload in vlan 112 in the network infrastructure.
The interface that connects to the outside network needs to be specified during netplugin
start, for this VM configuration it is set as `eth2`

Let's run some containers to belong to this network, one on each node. First one on 
`contiv-node3`

```
[vagrant@contiv-node3 ~]$ docker run -itd --name=contiv-vlan-c1 --net=contiv-vlan alpine /bin/sh
830e9ee01f2e7c64e51b10bc3990d03c6b5ec22d28985c3f49552ad93fc75d74
```

And another one on `contiv-node4`

```
[vagrant@contiv-node4 ~]$ docker run -itd --name=contiv-vlan-c2 --net=contiv-vlan alpine /bin/sh
a4fcd337342888520e0886d3f2cd304d78d1d8657ba868503b357dc6e5227476

[vagrant@contiv-node4 ~]$ docker exec -it contiv-vlan-c2 /bin/sh

/ # ping contiv-vlan-c1
PING contiv-vlan-c1 (10.1.3.1): 56 data bytes
64 bytes from 10.1.3.1: seq=0 ttl=64 time=3.051 ms
64 bytes from 10.1.3.1: seq=1 ttl=64 time=0.893 ms
64 bytes from 10.1.3.1: seq=2 ttl=64 time=0.840 ms
64 bytes from 10.1.3.1: seq=3 ttl=64 time=0.860 ms
64 bytes from 10.1.3.1: seq=4 ttl=64 time=0.836 ms
. . .
```

While this is going on `contiv-node4`, let's run tcpdump on eth2 on `contiv-node3`
and confirm how rx/tx packets look on it:

```
[vagrant@contiv-node3 ~]$ sudo tcpdump -e -i eth2 icmp
tcpdump: WARNING: eth2: no IPv4 address assigned
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), capture size 65535 bytes
05:13:57.641958 02:02:0a:01:03:01 (oui Unknown) > 02:02:0a:01:03:02 (oui Unknown), ethertype 802.1Q (0x8100), length 102: vlan 112, p 0, ethertype IPv4, 10.1.3.1 > 10.1.3.2: ICMP echo reply, id 2560, seq 0, length 64
05:13:58.642954 02:02:0a:01:03:01 (oui Unknown) > 02:02:0a:01:03:02 (oui Unknown), ethertype 802.1Q (0x8100), length 102: vlan 112, p 0, ethertype IPv4, 10.1.3.1 > 10.1.3.2: ICMP echo reply, id 2560, seq 1, length 64
05:13:59.643342 02:02:0a:01:03:01 (oui Unknown) > 02:02:0a:01:03:02 (oui Unknown), ethertype 802.1Q (0x8100), length 102: vlan 112, p 0, ethertype IPv4, 10.1.3.1 > 10.1.3.2: ICMP echo reply, id 2560, seq 2, length 64
^C
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Note: The vlan shown in tcpdump is same (i.e. `112`) as what we configured in the VLAN. After verifying this, feel free to stop the ping that is still running on 
`contiv-vlan-c2` container.


### Chapter 5: Docker Overlay multi-host networking

As we learned earlier that using the vxlan port conflict can prevent us from using
Docker `overlay` network. For us to experiment with this, we'd go ahead
and terminate `contiv` driver first on both nodes: `contiv-node3` and
`contiv-node4`:

```
[vagrant@contiv-node3 ~]$ sudo service netplugin stop
Redirecting to /bin/systemctl stop  netplugin.service
```

To try out overlay driver, we switch to `contiv-node3` and create an overlay network first.

```
[vagrant@contiv-node3 ~]$ docker network create -d=overlay --subnet=30.1.1.0/24 overlay-net
464aa012989d0736d277b5be55b7685ae42e36350fd3c8ae121721753edb497a

[vagrant@contiv-node3 ~]$ docker network inspect overlay-net
[
    {
        "Name": "overlay-net",
        "Id": "464aa012989d0736d277b5be55b7685ae42e36350fd3c8ae121721753edb497a",
        "Scope": "global",
        "Driver": "overlay",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "30.1.1.0/24"
                }
            ]
        },
        "Internal": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

Now, we can create few containers that belongs to `overlay-net`, which can get scheduled
on any of the available nodes by the scheduler. Note that we still have DOCKER_HOST set to point
to the swarm cluster.

```
[vagrant@contiv-node3 ~]$ docker run -itd --name=overlay-c1 --net=overlay-net alpine /bin/sh
82079ffd25d45731d0e1e3691211c055977c4e44e5ce1e0bea2c95ab9881fb02

[vagrant@contiv-node3 ~]$ docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' overlay-c1
30.1.1.2

[vagrant@contiv-node3 ~]$ docker run -itd --name=overlay-c2 --net=overlay-net alpine /bin/sh
825a80fb54c4360e48dbe1057a9682273df2811028ec5876cf26124024f6a702

[vagrant@contiv-node3 ~]$ docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED              STATUS              PORTS               NAMES
825a80fb54c4        alpine                           "/bin/sh"                38 seconds ago       Up 37 seconds                           contiv-node4/overlay-c2
82079ffd25d4        alpine                           "/bin/sh"                About a minute ago   Up About a minute                       contiv-node4/overlay-c1
cf720d2e5409        contiv/auth_proxy:1.0.0-beta.5   "./auth_proxy --tls-k"   3 hours ago          Up 3 hours                              contiv-node3/auth-proxy
2d450e95bb3b        quay.io/coreos/etcd:v2.3.8       "/etcd"                  4 hours ago          Up 4 hours                              contiv-node4/etcd
78c09b21c1fa        quay.io/coreos/etcd:v2.3.8       "/etcd"                  4 hours ago          Up 4 hours                              contiv-node3/etcd

[vagrant@contiv-node3 ~]$ docker exec -it overlay-c2 /bin/sh
/ # ping overlay-c1
PING overlay-c1 (30.1.1.2): 56 data bytes
64 bytes from 30.1.1.2: seq=0 ttl=64 time=0.096 ms
64 bytes from 30.1.1.2: seq=1 ttl=64 time=0.091 ms
64 bytes from 30.1.1.2: seq=2 ttl=64 time=0.075 ms
^C
--- overlay-c1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.075/0.087/0.096 ms

/ # exit
```

Very similar to contiv-networking, built in dns resolves the name `overlay-c1`
to the IP address of `overlay-c1` container and be able to reach another container
across using a vxlan overlay.

### Cleanup: **after all play is done**
To cleanup the setup, after doing all the experiments, exit the VM destroy VMs:

```
[vagrant@contiv-node3 ~]$ exit

$ cd .. (just to come out of cluster dir)
$ make cluster-destroy
cd cluster && vagrant destroy -f
==> contiv-node4: Forcing shutdown of VM...
==> contiv-node4: Destroying VM and associated drives...
==> contiv-node3: Forcing shutdown of VM...
==> contiv-node3: Destroying VM and associated drives...

```

### References
1. [CNI Specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
2. [CNM Design](https://github.com/docker/libnetwork/blob/master/docs/design.md)
3. [Contiv User Guide](http://docs.contiv.io)
4. [Contiv Networking Code](https://github.com/contiv/netplugin)


## Contiv Policy Features


### Chapter 1 - ICMP Policy

In this section, we will create two groups epgA and epgB. We will create container with respect to those groups. 
Then by default communication between group is allowed. So we will have ICMP deny policy and very that we are not able to ping among those containers.

Let us create Tenant and Network first.

```
netctl tenant create TestTenant

netctl network create --tenant TestTenant --subnet=20.1.1.0/24 --gateway=20.1.1.254 TestNet

netctl net ls -a


```

Now, create two groups epgA and epgB, under network TestNet.


```
netctl group create -t TestTenant TestNet epgA

netctl group create -t TestTenant TestNet epgB

netctl group ls -a

```

Now you will see thse groups and networks are reported as network to docker-engine, with driver listed as netplugin.


```

docker network ls


```

Now Let us create two containers on each group network and check whether they are abel to ping each other or not.
By default, Contiv allows ping between groups under same network.


```

docker run -itd --net="epgA/TestTenant" --name=AContainer contiv/alpine sh

docker run -itd --net="epgB/TestTenant" --name=BContainer contiv/alpine sh

docker ps

```

Now try to ping from AContainer to BContainer. They should be able to ping each other.

```

docker exec -it BContainer sh

docker exec -it Acontainer sh

docker exec -it AContainer sh
/ # ifconfig

/ # ping 20.1.1.2

/ # exit


```

Now add ICMP Deny policy. Container should not be abel to ping each other now.

Adding policy and modifying group.

```

netctl policy create -t TestTenant policyAB

netctl policy rule-add -t TestTenant -d in --protocol icmp  --from-group epgA  --action deny policyAB 1

netctl group create -t TestTenant -p policyAB TestNet epgB

netctl policy ls -a

netctl policy rule-ls -t TestTenant policyAB

```

Now ping between containers.


```

docker exec -it AContainer sh
/ # ping 20.1.1.2

/ # exit

```

### Chapter 2 - TCP Policy

In this section, We will add TCP 8001 port allow policy and then will verify this policy.

Creating TCP port policy.

```

netctl policy rule-add -t TestTenant -d in --protocol tcp --port 8001  --from-group epgA  --action allow policyAB 3

netctl policy rule-ls -t TestTenant policyAB


```

Now check that from app group, only TCP 8001 port is open. To test this, Let us run iperf on BContainer and
verify using nc utility on BContainer.


```
On AContainer:

docker exec -it AContainer sh
/ # iperf -s -p 8001
------------------------------------------------------------
Server listening on TCP port 8001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------



On BContainer:

docker exec -it BContainer sh
/ # nc -zvw 1 20.1.1.1 8001 -------> here 10.1.1.1 is IP address of AContainer.
10.1.1.1 (10.1.1.1:8001) open
/ # nc -zvw 1 20.1.1.1 8000
/ #

You see that port 8001 is open and port 8000 is not open.

```


### Chapter 3 - Bandwidth Policy

In this chapter, we will explore bandwidth policy feature of contiv. 
We will create tenant, network and groups. Then we will attach netprofile to one group
and verify that applied bandwidth is working or not as expected in data path.


So, let us create tenant, a network and group "A" under network.


```
netctl tenant create BandwidthTenant

netctl network create --tenant BandwidthTenant --subnet=50.1.1.0/24 --gateway=50.1.1.254 -p 1001 -e "vlan" BandwidthTestNet

netctl group create -t BandwidthTenant BandwidthTestNet epgA

netctl net ls -a

```

Now, We are going to run serverA and clientA containers using group epgA as a network.


```

docker run -itd --net="epgA/BandwidthTenant" --name=serverA contiv/alpine sh

docker run -itd --net="epgA/BandwidthTenant" --name=clientA contiv/alpine sh

docker ps

```

Now run iperf server and client to find out current bandwidth which we are getting on the network
where you are running this tutorial. It may vary depending upon base OS , network speed etc.


```
On serverA:

docker exec -it serverA sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:02:32:01:01:01
          inet addr:50.1.1.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::2:32ff:fe01:101%32741/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1296 (1.2 KiB)  TX bytes:648 (648.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1%32741/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

/ # iperf -s -u
------------------------------------------------------------
Server listening on UDP port 5001
Receiving 1470 byte datagrams
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
[  3] local 50.1.1.1 port 5001 connected with 50.1.1.2 port 34700
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total Datagrams
[  3]  0.0-10.0 sec  1.25 MBytes  1.05 Mbits/sec   0.028 ms    0/  893 (0%)


On clientA:

[vagrant@contiv-node4 ~]$ docker exec -it clientA sh
/ # iperf -c 50.1.1.1 -u
------------------------------------------------------------
Client connecting to 50.1.1.1, UDP port 5001
Sending 1470 byte datagrams
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
[  3] local 50.1.1.2 port 34700 connected with 50.1.1.1 port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec  1.25 MBytes  1.05 Mbits/sec
[  3] Sent 893 datagrams
[  3] Server Report:
[  3]  0.0-10.0 sec  1.25 MBytes  1.05 Mbits/sec   0.027 ms    0/  893 (0%)
/ #

```

Now we see that, current bandwidth we are getting is 1.05 Mbits/sec.
So let us create new group B and create netprofile with bandwidth less than the one 
we got above. So let us create netprofile with bandwidth of 500Kbits/sec.

```

[vagrant@contiv-node3 ~]$ netctl netprofile create -t BandwidthTenant -b 500Kbps -d 6 -s 80 testProfile
Creating netprofile BandwidthTenant:testProfile
[vagrant@contiv-node3 ~]$ netctl group create -t BandwidthTenant -n testProfile BandwidthTestNet epgB
Creating EndpointGroup BandwidthTenant:epgB
[vagrant@contiv-node3 ~]$ netctl netprofile ls -a
Name         Tenant           Bandwidth  DSCP      burst size
------       ------           ---------  --------  ----------
testProfile  BandwidthTenant  500Kbps    6         80
[vagrant@contiv-node3 ~]$ netctl group ls -a
Tenant           Group  Network           IP Pool   Policies  Network profile
------           -----  -------           --------  ---------------
BandwidthTenant  epgA   BandwidthTestNet
BandwidthTenant  epgB   BandwidthTestNet              testProfile
[vagrant@contiv-node3 ~]$


```

Running clientB and serverB containers:

```

[vagrant@contiv-node3 ~]$ docker run -itd --net="epgB/BandwidthTenant" --name=serverB contiv/alpine sh
2f4845ed86c5496537ccece77683354e447c28df8f00c10a1a175eb5f44aee76
[vagrant@contiv-node3 ~]$ docker run -itd --net="epgB/BandwidthTenant" --name=clientB contiv/alpine sh
00dde4f46c360e517695e44f2690590ec0af26e125254102147fe79b76331339
[vagrant@contiv-node3 ~]$ docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS              PORTS               NAMES
00dde4f46c36        contiv/alpine                    "sh"                     2 seconds ago       Up 1 seconds                            contiv-node4/clientB
2f4845ed86c5        contiv/alpine                    "sh"                     4 seconds ago       Up 3 seconds                            contiv-node3/serverB
c783d6c3f546        contiv/alpine                    "sh"                     12 minutes ago      Up 12 minutes                           contiv-node4/clientA
6112c6697df2        contiv/alpine                    "sh"                     12 minutes ago      Up 12 minutes                           contiv-node4/serverA
b6e0601d8c13        contiv/auth_proxy:1.0.0-beta.6   "./auth_proxy --tls-k"   17 minutes ago      Up 17 minutes                           contiv-node3/auth-proxy
0c3cb365e573        quay.io/coreos/etcd:v2.3.8       "/etcd"                  20 minutes ago      Up 20 minutes                           contiv-node4/etcd
a9536ad281be        quay.io/coreos/etcd:v2.3.8       "/etcd"                  20 minutes ago      Up 20 minutes                           contiv-node3/etcd
[vagrant@contiv-node3 ~]$


```

Now as we are running clientB and serverB containers on group B network. we should see bandwidth around
500Kbps. Thats the verification that our bandwidth netprofile is working as per expectation.

```

On serverB:

[vagrant@contiv-node3 ~]$ docker exec -it serverB sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:02:32:01:01:03
          inet addr:50.1.1.3  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::2:32ff:fe01:103%32525/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1296 (1.2 KiB)  TX bytes:648 (648.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1%32525/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

/ # iperf -s -u
------------------------------------------------------------
Server listening on UDP port 5001
Receiving 1470 byte datagrams
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
[  3] local 50.1.1.3 port 5001 connected with 50.1.1.4 port 57180
[ ID] Interval       Transfer     Bandwidth        Jitter   Lost/Total Datagrams
[  3]  0.0-10.3 sec   692 KBytes   552 Kbits/sec  15.720 ms  411/  893 (46%)


On clientB:

[vagrant@contiv-node3 ~]$ docker exec -it clientB sh
/ # iperf -c 50.1.1.3 -u
------------------------------------------------------------
Client connecting to 50.1.1.3, UDP port 5001
Sending 1470 byte datagrams
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
[  3] local 50.1.1.4 port 57180 connected with 50.1.1.3 port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec  1.25 MBytes  1.05 Mbits/sec
[  3] Sent 893 datagrams
[  3] Server Report:
[  3]  0.0-10.3 sec   692 KBytes   552 Kbits/sec  15.720 ms  411/  893 (46%)


As we see, clientB is getting roughly around 500Kbps bandwidth.

```


### Cleanup: 
To cleanup the setup, after doing all the experiments, exit the VM destroy VMs:

```
[vagrant@contiv-node3 ~]$ exit

$ cd .. (just to come out of cluster dir)
$ make cluster-destroy
cd cluster && vagrant destroy -f
==> contiv-node4: Forcing shutdown of VM...
==> contiv-node4: Destroying VM and associated drives...
==> contiv-node3: Forcing shutdown of VM...
==> contiv-node3: Destroying VM and associated drives...

```
