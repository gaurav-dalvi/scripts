Skip to content
This repository
Search
Pull requests
Issues
Gist
 @gaurav-dalvi
 Unwatch 1
  Star 0
 Fork 0 gaurav-dalvi/scripts
 Code  Issues 0  Pull requests 0  Projects 0  Wiki  Pulse  Graphs  Settings
scripts/ 
ContivTroubleshooting.md
   or cancel
    
 Edit file    Preview changes
1
​
2
# Contiv Troubleshooting Document
3
​
4
## Information about this installation
5
​
6
In this installation, we will be installing following components using ansible 2.2.0.0
7
​
8
1: netplugin and netmaster - `v0.1-12-23-2016.19-44-42.UTC`
9
```
10
netplugin --version or netmaster --version will give you version of each component running in
11
this setup
12
```
13
​
14
2: etcd - 2.3.1
15
​
16
3: Docker Swarm - 1.2.5
17
​
18
4: OpenVSwitch - 2.3.1-2.el7
19
​
20
5: Docker Engine - 1.12
21
​
22
​
23
## Troubleshooting Techniques:
24
​
25
### 1: Make sure you have passwordless SSH setup.
26
​
27
To setup passwordless SSH, please use this : http://twincreations.co.uk/pre-shared-keys-for-ssh-login-without-password/
28
​
29
If you have 3 nodes, Node1 Node2 and Node3 then please make sure you can do passwordless SSH from
30
​
31
Node1 to Node1
32
​
33
Node1 to Node2
34
​
35
Node1 to Node3
36
​
37
### 2: Make sure your etcd cluster is healthy
38
​
39
```
40
sudo etcdctl cluster-health
41
member 903d536c85a35515 is healthy: got healthy result from http://10.193.231.222:2379
42
member fa77f6921bc496d6 is healthy: got healthy result from http://10.193.231.245:2379
43
cluster is healthy
44
​
45
```
46
​
47
### 3: Make sure your docker swarm cluster is healthy
48
​
49
When you do run `docker info` command, You should be able to see
50
​
@gaurav-dalvi
Commit changes

Update 

Add an optional extended description…
  Commit directly to the master branch.
  Create a new branch for this commit and start a pull request. Learn more about pull requests.
Commit changes  Cancel
Contact GitHub API Training Shop Blog About
© 2017 GitHub, Inc. Terms Privacy Security Status Help
