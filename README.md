# HDFS-installation
A set of scripts for installation of HDFS

## SSH-Keygen
This script is aimed at setting up the SSH keys in the servers so the slaves/children can communicate with the master. Replace `(<master-port> <username>@<master-machine-name>)` with suitable values which can be obtained from the cloudlab experiment portal. 

- **Master should always be node0.**
- **This script should be run from your local computer which has ssh access to the cloudlab machines.**
- After the script completes, ensure that you can ssh to the slave nodes from the master. Also, ensure that slaves are added to the ssh `known_hosts` of the master. You can do that by executing `ssh node1` and `ssh node2` from `node0`.
- **Optional** You can also disable SSH strict host checking by adding these lines in `~/.ssh/config`.
```
Host *
    StrictHostKeyChecking no
```

An example is shown below.
```
 For login ssh command ssh -p 27010 amondal5@clnode136.clemson.cloudlab.us
 replacement (27010 amondal5@clnode136.clemson.cloudlab.us)
```

## HDFS-installation
This script is aimed at installation of HDFS in all the nodes. 

- Copy the script to `node0` or master (**Both should be same**). This node will be where the primary namenode will be running. 
- Run `lsblk` on all the three nodes and ensure that `xvad4` is the disk to be mounted.
- Execute the script by `bash hdfs-install.sh all xvad4` and you are free to take a coffee break.
- After completion, run `source ~/.bashrc` to reload the new path variables. 
- Run `hdfs dfs -help` to see if HDFS is successfully running on master. *Slaves will have HDFS installed but paths might not be set correctly which is fine.*
- Run `jps` on all nodes. *Namenode should be running on master only. Datanodes should be running on all nodes. There can be a secondary namenode running in any of the nodes.*

## Debug hints

- **HDFS commands will be recognized only for the user whose login is used for HDFS installation.** Others have to add paths manually in their `.bashrc` file for HDFS to work. See the function `format_and_start_dfs` in the installation script for more details.
- The script has some basic checkpoints and it will trap and exit if it fails to execute some command.
- It is advisable to gloss through the script before executing.
- The script can be executed in sections. Follow the switch case options and execute functions one by one to spot the error.
- **The script will format the entire xvad4 partition. Copy any readings or other important files that might be in `/mnt/data`. Your home directory is a safe place for backups.**
- The script can figure out the master IP on it's own. Enusre that the master IP is found correctly by executing `ifconfig | grep "inet" | grep "10.10" | xargs | cut -d " " -f 2` and comparing it with the expected value. If not working as expected, replace `LOCAL_IP` with the expected value in the installation script.
- It is preferable that this script is executed from one particular user only. Setting `ssh keys` from one user and running the script from another user will be problematic. Please use only one user-login if possible.
- Run `cat /mnt/data/hadoop-3.3.4/etc/hadoop/hdfs-site.xml` on all nodes to see if HDFS properties are set correctly.
- Run `cat /mnt/data/hadoop-3.3.4/etc/hadoop/core-site.xml` on all nodes to see if the namenode IP is set correctly
