# Contiv Installer

![Contiv Installer](https://raw.githubusercontent.com/gaurav-dalvi/scripts/master/contiv-related/Installer.png)

## About Contiv Installer:

Contiv swarm installer is launched from a host external to the cluster. All the nodes need to be accessible to the installer host. Please refer above diagram. As diagram suggests, You can have one or many master nodes and any number of worker nodes. 
As a part of installer, we are going to install following softwares on all the nodes in the cluster.

| Component        | Version    |
| ------------- |:-------------:| 
| Docker engine  | 1.12.6 | 
| Docker Swarm   | 1.2.5  |
| etcd KV store  | 2.3.7  |
| Contiv         | v1.0.0-alpha-01-28-2017.10-23-11.UTC |
| ACI-GW container| contiv/aci-gw:02-02-2017.2.1_1h |


## 

Download the install bundle <TODO add a location here>. This is of the form contiv-VERSIONTAG.tgz.
Extract the install bundle tar xvzf contiv-VERSIONTAG.tgz
cd to the extracted folder cd contiv-VERSIONTAG
To load the installer container image run docker load -i contiv-install-image.tar
Run ./install/ansible/install_swarm.sh -f <host config file> -n <contiv master> -e <ansible ssh key> -a <additional ansible options> to install Contiv without the scheduler stack.
Run ./install/ansible/install_swarm.sh -f <host config file> -n <contiv master> -e <ansible ssh key> -a <additional ansible options> -i to install Contiv with the scheduler stack.
To specify a user to user for the Ansible ssh login, specify "-u " as the additional andible option.
Example host config file is available at install/ansible/cfg.yml
To see additional install options run ./install/ansible/install_swarm.sh.
