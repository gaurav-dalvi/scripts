#!/bin/bash

mkdir UPGRADE
echo "Created UPGRADE dir"
cd UPGRADE
git clone git@github.com:gaurav-dalvi/$1.git
echo "Cloning my forked repo"
cd $1
git remote add upstream git@github.com:contiv/$1.git
echo "Adding main repo as upstream"
git pull upstream master
echo "Pulling it from upstream master to local master"
git push origin master
echo "Pushing latest changes to local master"

echo "deleting $1 repo and base dir"
cd ..
cd ..
rm -rf UPGRADE
