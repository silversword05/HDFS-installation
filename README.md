# HDFS-installation
A set of scripts for installation of HDFS

## SSH-Keygen
This script is aimed at setting up the SSH keys in the servers so the slaves/children can communicate with the master. Replace `(<master-port> <username>@<master-machine-name>)` with suitable values which can be obtained from the cloudlab experiment portal. 

- **Master should always be node0.**
- **This script should be run from your local computer which has ssh access to the cloudlab machines.**
- After the script completes, ensure that you can ssh to the slave nodes from the master. Also, ensure that slaves are added to the ssh `known_hosts` of the master.

An example is shown below.
```
 For login ssh command ssh -p 27010 amondal5@clnode136.clemson.cloudlab.us
 replacement (27010 amondal5@clnode136.clemson.cloudlab.us)
```

## HDFS-installation
This script is aimed at installation of HDFS in all the nodes. 
