# Contiv
Contiv is a Open Sourced Policy Based Container for Networking, the idea behind Contiv is to make it easier for end users to deploy micro-services in their environments

## Need for Contiv

With the advent of Containers and hence Microservices architecture, there is a need of automated or programmable network infrastructure specifically catering to dynamic workloads which can be formed using containers. With container and microservices technologies, speed and scale becomes critical. Automation is must here. Network provisioning should also be made it through automation. 

Also with Baremetal hosts, VMs and Container, we have different layers of Virtualization abstraction. Encapusulation of packet becomes tricky. With Public cloud technologies, we need tenant level isolation as well for our container workloads.

## What is Contiv

Contiv provides a higher level of networking abstraction for microservices. Contiv secures your application using a rich policy framework. It provides built-in service discovery and service routing for scale out services.

Contiv provides IP address per container and eliminates the need for host-based port NAT. It works with different kinds of networks like pure layer 3 networks, overlay networks, and layer 2 networks, and it provides the same virtual network view to containers regardless of the underlying technology. Contiv works with all major schedulers like Kubernetes, Docker Swarm, Mesos, Nomad. These schedulers provide compute resources to your containers and Contiv provides networking to them. Contiv supports both CNM (Docker's networking Architecture) and CNI (CoreOS, Kubernetes's networking architecture). Contiv has L2, L3 (BGP), Overlay (VXLAN) and ACI modes. It has build in east-west service load balancing. Contiv also provides traffic isolation through control and data traffic.

### Architecture Diagram of Contiv

![](https://github.com/gaurav-dalvi/scripts/blob/master/contiv-related/Contiv-HighLevel-Architecture.png?raw=true)

Contiv comprise of Netmaster (Contiv Master in above diagram) and Netplugin (Contiv Host Agent in above diagram). Netmaster has REST server which exposes functionality of Contiv. Netctl is CLI calling these exposed REST services exposed by Netmaster. 

Contiv uses Distributed Key Value store like etcd or consul, to maintain states of all the objects. Netmaster manages global resources like IPAM, VLAN, VXLAN pools via Distributed Key Value. Netmaster also implements network wide policy. Netmaster can be started in HA mode, so that you dont have single point of failure. Hearbeat mechanism is provided to communicate between different netmasters.

### Netmaster and Netplugin

![](https://github.com/gaurav-dalvi/scripts/blob/master/contiv-related/Contiv-Network-Components.png?raw=true)

#### Netmaster:

This one binary performs so many tasks for Contiv. Its REST API server which can handle multiple requests simultaneously. It learns routes and distributes to Netplugin nodes. It acts as resource manager which does resource allocation of IP addresses, VLAN and VXLAN IDs for networks. It uses distributed state store like etcd or consul to save all the desire runtime of for contiv objects. Because of which contiv becomes completely stateless, scalabel and restart-able. Netmaster has in built hearbeat mechanism , through which it can talk to peer netmasters. So this avoids risk of single point failure. Netmaster can work with external integration manager (Policy engine) like ACI.

#### Netplugin:
Each Host agent (Netplugin) is actually implementing [CNI](https://github.com/containernetworking/cni/blob/master/SPEC.md) or [CNM](https://github.com/docker/libnetwork/blob/master/docs/design.md) networking model adopted by popular Container orchestration engines like Kubernates, Docker Swarm, Mesos, Nomad etc. It does communication with netmaster over REST Interface. In addition to this Contiv uses json-rpc to distribute endpoints from netplugin to netmaster.

The integration with ACI, it addresses basic use cases such as Infrastructure automation, Application aware Infrastructure, Scale out models and Dynamic Applications which are key pillars of Modern Day Microservices architectures.

Contiv working with ACI, demonstrates how this integration can be achieved in a docker containerized environment to create objects and associations that enable containers to communicate according to policy intent.
