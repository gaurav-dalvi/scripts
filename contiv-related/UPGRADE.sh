#!/bin/bash

repolist=(
   netplugin
   ansible
   install
   modelgen
   contiv-ui
   auth_proxy
   ofnet
   remotessh
   contiv.github.io
   contivmodel
   aci-gw
   stash
   libOpenflow
   libovsdb
   ccn
   build
)

echo "*******************Script has started**********************"

for i in ${repolist[@]}; do
	mkdir UPGRADE
	echo "Created UPGRADE dir"
	cd UPGRADE
	git clone git@github.com:gaurav-dalvi/${i}.git
	echo "Cloning my forked repo"
	cd ${i}
	git remote add upstream git@github.com:contiv/${i}.git
	echo "Adding main repo as upstream"
	git pull upstream master
	echo "Pulling it from upstream master to local master"
	git push origin master
	echo "Pushing latest changes to local master"
	echo "~~~~~~~~~~~~deleting ${i} repo and base dir"
	cd ..
	cd ..
	rm -rf UPGRADE
done

rm -rf UPGRADE

echo "*******************Script has finished**********************"

exit 0
