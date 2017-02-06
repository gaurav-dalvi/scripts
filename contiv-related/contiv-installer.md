# Contiv Installer

![Contiv Installer](https://raw.githubusercontent.com/gaurav-dalvi/scripts/master/contiv-related/Installer.png)

## About Contiv Installer:

Contiv swarm installer is launched from a host external to the cluster (Install host in above diagram). All the nodes need to be accessible to the installer host. Please refer above diagram. As diagram suggests, You can have one or many master nodes and any number of worker nodes. Installer installs netmaster, netplugin, aci-gw container, etcd, docker, swarm manager on master nodes. It will install netplugin, docker, swarm agent on worker nodes.

As a part of installer, we are going to install following components on all the nodes in the cluster.

| Component        | Version    |
| ------------- |:-------------:| 
| Docker engine  | 1.12.6 | 
| Docker Swarm   | 1.2.5  |
| etcd KV store  | 2.3.7  |
| Contiv         | v1.0.0-alpha-01-28-2017.10-23-11.UTC |
| ACI-GW container| contiv/aci-gw:02-02-2017.2.1_1h |


## How to use Installer :

To get installer please refer : https://github.com/contiv/install/releases

Download the install bundle, save it and extract it on Install host.

### Installer Usage:

`./install/ansible/install_swarm.sh -f <host configuration file>  -e <ssh key> -u <ssh user> OPTIONS`

Options:
```
-f   string                 Configuration file listing the hostnames with the control and data interfaces and optionally ACI parameters
-e  string                  SSH key to connect to the hosts
-u  string                  SSH User
-i                          Install the swarm scheduler stack

Options:
-m  string                  Network Mode for the Contiv installation (“standalone” or “aci”). Default mode is “standalone” and should be used for non ACI-based setups
-d   string                 Forwarding mode (“routing” or “bridge”). Default mode is “bridge”

Advanced Options:
-v   string                 ACI Image (default is contiv/aci-gw:latest). Use this to specify a specific version of the ACI Image.
-n   string                 DNS name/IP address of the host to be used as the net master  service VIP.

```

Additional parameters can also be updated in install/ansible/env.json file.

### Examples:

```
1. Install Contiv with Docker Swarm on hosts specified by cfg.yml.
./install/ansible/install_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i

2. Install Contiv on hosts specified by cfg.yml. Docker should be pre-installed on the hosts.
./install/ansible/install_swarm.sh -f cfg.yml -e ~/ssh_key -u admin

3. Install Contiv with Docker Swarm on hosts specified by cfg.yml in ACI mode.
./install/ansible/install_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i -m aci

4. Install Contiv with Docker Swarm on hosts specified by cfg.yml in ACI mode, using routing as the forwarding mode.
./install/ansible/install_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i -m aci -d routing

```

### Uninstaller Usage: 

` ./install/ansible/uninstall_swarm.sh -f <host configuration file>  -e <ssh key> -u <ssh user> OPTIONS`

Options: 
```
-f   string            Configuration file listing the hostnames with the control and data interfaces and optionally ACI parameters
-e  string             SSH key to connect to the hosts
-u  string             SSH User
-i                     Uninstall the scheduler stack

Options:
-r                     Reset etcd state and remove docker containers
-g                     Remove docker images
```

Additional parameters can also be updated in install/ansible/env.json file.

```
Examples:
1. Uninstall Contiv and Docker Swarm on hosts specified by cfg.yml.
./install/ansible/uninstall_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i
2. Uninstall Contiv and Docker Swarm on hosts specified by cfg.yml for an ACI setup.
./install/ansible/uninstall_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i -m aci
3. Uninstall Contiv and Docker Swarm on hosts specified by cfg.yml for an ACI setup, remove all containers and Contiv etcd state
./install/ansible/uninstall_swarm.sh -f cfg.yml -e ~/ssh_key -u admin -i -m aci -r
```
