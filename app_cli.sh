#!/bin/bash
# Sample script to perform contiv cli configuration with ACI integration

# Function to get user confirmation to proceed
function ConfirmPrompt {
  set +v
  while true; do
  read -p "Ready to proceed(y/n)? " choice
  if [ "$choice" == "y" ]; then
      break
  fi

  if [ "$choice" == "n" ]; then
      echo "Try again when you are ready."
      exit 1
  else
      echo "Please answer y or n"
      continue
  fi
  done
  set -v
}

# -------------------  Specify the correct vlan range here...
netctl aci-gw set -n "topology/pod-1/node-101,topology/pod-1/node-102" -d "TEST-Phys-Dom" -e yes -i no
netctl global set --fabric-mode aci --vlan-range 1100-1200
netctl global info

ConfirmPrompt

# ------------------- Create a tenant named ge
netctl tenant create ge
netctl tenant ls

# ------------------- Create external contracts

netctl external-contracts create --tenant ge -c --contract "uni/tn-ge/brc-icmpAllow" vmConsumed
netctl external-contracts create --tenant ge -p --contract "uni/tn-ge/brc-icmpAllow" vmProvided

# ------------------- Choose the subnet you like...

netctl net create -t ge -e vlan -s 20.1.1.1/24 -g 20.1.1.254 ge-net1
netctl net ls -t ge

ConfirmPrompt

# ------------------- Creating two EPGs : app and db
netctl group create -t ge -e vmConsumed -e vmProvided ge-net1 app
netctl group create -t ge ge-net1 db

# ------------------- Running docker ps command to check docker container creation

docker ps 

ConfirmPrompt

# ------------------- Push app-profile to ACI 

netctl app-profile create -t ge -g app,db ge-profile
netctl app-profile ls -t ge

# ------------------- Creating containers with app/ge and db/ge as a network

docker run -itd --net="app/ge" --name=app1 jainvipin/web /bin/bash
docker run -itd --net="db/ge" --name=db1 jainvipin/redis /bin/bash

# ------------------- At this point, you will see the app profile created in ACI

ConfirmPrompt

# ------------------- now confirm that app1 container CAN NOT ping db1 container

ConfirmPrompt

# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Now create ICMP allow policy so that these container can ping each other.

netctl policy create -t ge app2db
netctl policy rule-add -t ge -d in --protocol icmp  --from-group app  --action allow app2db 1
netctl group create -t ge -p app2db ge-net1 db

ConfirmPrompt

# ------------------- now confirm that app1 container CAN ping db1 container

ConfirmPrompt

# ------------------- Now allow TCP port 6379 between these containers

netctl policy rule-add -t ge -d in --protocol tcp --port 6379 --from-group app  --action allow app2db 2

# ------------------- Confirm that port 6379 is allowed between these Containers
ConfirmPrompt

# ------------------- Confirm that external VM can be reachable from Containers in Contiv
ConfirmPrompt

# ------------------- Cleaning up all the containers, networks and groups."

docker stop $(docker ps -a | grep web | awk '{print $1}')
docker stop $(docker ps -a | grep redis | awk '{print $1}') 
docker rm $(docker ps -a | grep web | awk '{print $1}')
docker rm $(docker ps -a | grep redis | awk '{print $1}')


netctl app-profile rm -t ge ge-profile
netctl group rm -t ge app
netctl group rm -t ge db
netctl external-contracts rm --tenant ge  vmConsumed
netctl external-contracts rm --tenant ge  vmProvided
netctl policy rm -t ge app2db
netctl network rm -t ge ge-net1
