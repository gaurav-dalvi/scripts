# How Setup Contiv on AWS:

## Contiv + Swarm on AWS

- Please install Terrafrom https://www.terraform.io/intro/getting-started/install.html before you try this.
- Install Docker 1.12.x on the host from which you are going try these commands


In this installation we will install following on AWS EC2 instances.
```
Docker Enginer
Docker swarm
Contiv services
```

0: Consider `/home/foo` is our workspace. 

1: Download Terraform script
```
wget https://raw.github.com/contiv/ansible/master/aws.tf
```
2: Now create aws.tfvars file

```
aws_access_key = "<Your key here>"
aws_secret_key = "<Your key here>"

ssh_keypair = "<you ssh key>"
key_path = "<your pem file path>"

# for security group & vpc
our_security_group_id = "sg-83b3abe6"
our_vpc_id = "vpc-2bf7264e"
```

3: Download contiv installer.

```
wget https://github.com/contiv/install/releases/download/${params["CONTIV_INSTALLER_VERSION"]}/contiv-${params["CONTIV_INSTALLER_VERSION"]}.tgz
```
For reference, you can look here : https://github.com/contiv/install/releases

4: Download following file:
`https://github.com/contiv/stash/blob/master/CI/contiv_cfg_generator.py`

You will need to have access to repo contiv/stash


5: Execute terrraform script

`terraform apply -var buildnum=<uniqueue number> -var-file aws.tfvars`

6: Copy aws key to all the EC2 isntances so that we can have passwordless SSH amaong them

```
scp -o StrictHostKeyChecking=no -i <key_path> <key_path> centos@IP:/home/centos/.ssh/
```

7: Getting Public IPs from AWS instances and generating result.yml file

```
terraform output public_ip_addresses

get all the IPs and the create comma separated string

Generate cfg.yml like this :

<Not working>
python ./contiv_cfg_generator.py aws <comma separated public IPs>

```

8 : Install contiv

```
tar xvf contiv-${params["CONTIV_INSTALLER_VERSION"]}.tgz
cd contiv-${params["CONTIV_INSTALLER_VERSION"]}; 
./install/ansible/install_swarm.sh -e <key_path> -u centos -f <result.yml file path> -i
```

9: To destroy this setup:

```
cd /home/foog
terraform destroy .
```
