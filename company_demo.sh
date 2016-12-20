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
netctl global set --fabric-mode aci --vlan-range 1150-1180
netctl global info

ConfirmPrompt

# ------------------- Create a tenant 
netctl tenant create TestTenant
netctl tenant ls

# ------------------- Choose the subnet you like...

netctl net create -t TestTenant -e vlan -s 40.1.1.1/24 -g 40.1.1.254 net1
netctl net ls -t TestTenant

ConfirmPrompt

# ------------------- Creating two EPGs : app and db

netctl group create -t TestTenant net1 app
netctl group create -t TestTenant net1 db

# ------------------- Push app-profile to ACI

netctl app-profile create -t TestTenant -g app,db TestTenant-profile
netctl app-profile ls -t TestTenant

# ------------------- At this point, you will see the app profile created in ACI

ConfirmPrompt

# ------------------- Creating containers with app/TestTenant and db/TestTenant as a network

docker run -itd --net="app/TestTenant" --name=app1 contiv/web /bin/bash
docker run -itd --net="db/TestTenant" --name=db1 contiv/redis /bin/bash

# ------------------- Running docker ps command to check docker container creation

docker ps

ConfirmPrompt

# ------------------- now confirm that app1 container CAN NOT ping db1 container

ConfirmPrompt

# ------------------- Testing the policies and rules which we have applied on app and db groups.

# ------------------- Now create ICMP allow policy so that these container can ping each other.

netctl policy create -t TestTenant app2db

netctl group create -t TestTenant -p app2db net1 db

netctl group create -t TestTenant net1 app

netctl policy rule-add -t TestTenant -d in --protocol icmp  --from-group app  --action allow app2db 1

ConfirmPrompt

# ------------------- now confirm that app1 container CAN ping db1 container

ConfirmPrompt

# ------------------- Now confirm that port range 6375-6379 is not open

ConfirmPrompt

# ------------------- Now allow TCP port 6379 between these containers

netctl policy rule-add -t TestTenant -d in --protocol tcp --port 6379 --from-group app  --action allow app2db 2

# ------------------- Confirm that port 6379 is allowed between these Containers

ConfirmPrompt

# ------------------- Cleaning up all the containers, networks and groups."

docker stop $(docker ps -a | grep web | awk '{print $1}')
docker stop $(docker ps -a | grep redis | awk '{print $1}')
docker rm $(docker ps -a | grep web | awk '{print $1}')
docker rm $(docker ps -a | grep redis | awk '{print $1}')


netctl app-profile rm -t TestTenant telenor-profile
netctl group rm -t TestTenant app
netctl group rm -t TestTenant db
netctl policy rm -t TestTenant app2db
netctl network rm -t TestTenant net1
netctl tenant rm TestTenant
