#!/bin/bash
trap "exit" INT

LOCAL_IP=$(ifconfig | grep "inet" | grep "10.10" | xargs | cut -d " " -f 2)
REPLICATION_FAC=2
HEART_BEAT_INTERVAL=15000
CHECKPOINT_INTERVAL=120

java_install() {
  sudo apt update -y
  sudo apt install openjdk-8-jdk -y
  sudo apt install xmlstarlet -y
  sudo apt install python3-pip -y
  sudo apt install sysstat
  update-alternatives --display java
}

java_install_all() {
  java_install
  ssh -tt node1 "$(declare -f java_install); java_install"
  ssh -tt node2 "$(declare -f java_install); java_install"
}

mount_disk() {
  case "$1" in
  sdc | xvad4 | sdb) echo "Choosing the disk $1" ;;
  *)
    echo "Cannot recognize disk $1"
    exit 1
    ;;
  esac
  sudo mkfs.ext4 /dev/"$1" <<<$'\ny'
  if mount | grep /mnt/data >/dev/null; then
    echo "unmount /mnt/data"
    sudo umount /mnt/data
  else
    echo "Creating directory /mnt/data"
    sudo mkdir -p /mnt/data
  fi
  sudo mount /dev/"$1" /mnt/data
  df -h | grep 'data'
}

mount_disk_all() {
  mount_disk "$1"
  ssh -tt node1 "$(declare -f mount_disk); mount_disk $1"
  ssh -tt node2 "$(declare -f mount_disk); mount_disk $1"
}

apache_download() {
  cd /mnt/data || {
    echo 'Failed to find directory /mnt/data'
    exit 1
  }
  sudo chmod 775 . || {
    echo 'Permission error /mnt/data'
    exit 1
  }
  if test -f "hadoop-3.3.4.tar.gz"; then
    echo "hadoop-3.3.4.tar.gz exists. Using previous tar"
  else
    wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz
  fi
  rm -rf hadoop-3.3.4
  tar zvxf hadoop-3.3.4.tar.gz
}

apache_download_all() {
  apache_download
  ssh -tt node1 "$(declare -f apache_download); apache_download"
  ssh -tt node2 "$(declare -f apache_download); apache_download"
}

set_hdfs_ip_conf() {
  echo "Master IP found $1"
  cd /mnt/data/hadoop-3.3.4/etc/hadoop || {
    echo 'Failed to find /mnt/data/hadoop-3.3.4/etc/hadoop'
    exit 1
  }
  CONF_SET=$(grep -c "fs.default.name" core-site.xml | sed 's/[^0-9]*//g')
  if [[ $CONF_SET -eq 0 ]]; then
    xmlstarlet ed --pf --inplace \
      -s "/configuration" -t elem -n "property" -v "" \
      -s "//property" -t elem -n "name" -v "fs.default.name" \
      -s "//property" -t elem -n "value" -v "$1" \
      core-site.xml
    xmlstarlet ed -L -O core-site.xml
  else
    echo "Configuration seems to be already set $(hostname)"
    exit 1
  fi
}

set_hdfs_ip_conf_all() {
  set_hdfs_ip_conf "$LOCAL_IP"
  ssh -tt node1 "$(declare -f set_hdfs_ip_conf); set_hdfs_ip_conf $LOCAL_IP"
  ssh -tt node2 "$(declare -f set_hdfs_ip_conf); set_hdfs_ip_conf $LOCAL_IP"
}

set_hdfs_dirs_conf() {
  NAME_NODE=/mnt/data/hadoop-3.3.4/name-node
  DATA_NODE=/mnt/data/hadoop-3.3.4/data-node
  mkdir -p "${NAME_NODE}" || {
    echo "Cannot create name-node dir"
    exit 1
  }
  mkdir -p "${DATA_NODE}" || {
    echo "Cannot create data-node dir"
    exit 1
  }
  cd /mnt/data/hadoop-3.3.4/etc/hadoop || {
    echo 'Failed to find /mnt/data/hadoop-3.3.4/etc/hadoop'
    exit 1
  }
  CONF_SET=$(grep -c "dfs.namenode.name.dir" core-site.xml | sed 's/[^0-9]*//g')
  if [[ $CONF_SET -eq 0 ]]; then
    xmlstarlet ed --pf --inplace \
      -s "/configuration" -t elem -n "property" -v "" \
      -s "//property" -t elem -n "name" -v "dfs.namenode.name.dir" \
      -s "//property" -t elem -n "value" -v "${NAME_NODE}" \
      -s "/configuration" -t elem -n "property2" -v "" \
      -s "//property2" -t elem -n "name" -v "dfs.datanode.data.dir" \
      -s "//property2" -t elem -n "value" -v "${DATA_NODE}" \
      hdfs-site.xml
    xmlstarlet ed --pf --inplace -r "//property2" -v "property" hdfs-site.xml
    xmlstarlet ed -L -O hdfs-site.xml
  else
    echo "Configuration seems to be already set $(hostname)"
    exit 1
  fi
}

set_hdfs_dirs_conf_all() {
  set_hdfs_dirs_conf
  ssh -tt node1 "$(declare -f set_hdfs_dirs_conf); set_hdfs_dirs_conf"
  ssh -tt node2 "$(declare -f set_hdfs_dirs_conf); set_hdfs_dirs_conf"
}

set_java_path() {
  JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
  CNT=$(update-alternatives --display java | grep -c "${JAVA_HOME}")
  if [[ CNT -eq 0 ]]; then
    echo "${JAVA_HOME} doesn't seem to be correct"
    exit 1
  fi
  cd /mnt/data/hadoop-3.3.4/etc/hadoop || {
    echo 'Failed to find /mnt/data/hadoop-3.3.4/etc/hadoop'
    exit 1
  }
  CONF_SET=$(grep -c "${JAVA_HOME}" hadoop-env.sh | sed 's/[^0-9]*//g')
  if [[ $CONF_SET -eq 0 ]]; then
    echo "export JAVA_HOME=${JAVA_HOME}" >>hadoop-env.sh
  else
    echo "Java Path seems to be already set $(hostname)"
    exit 1
  fi
}

set_java_path_all() {
  set_java_path
  ssh -tt node1 "$(declare -f set_java_path); set_java_path"
  ssh -tt node2 "$(declare -f set_java_path); set_java_path"
}

set_worker_ips() {
  cd /mnt/data/hadoop-3.3.4/etc/hadoop || {
    echo 'Failed to find /mnt/data/hadoop-3.3.4/etc/hadoop'
    exit 1
  }
  echo "$1" >workers
  echo "$2" >>workers
  echo "$3" >>workers
}

set_worker_ips_all() {
  CHILD_IP1=$(ssh -tt node1 "ifconfig | grep 'inet' | grep '10.10' | xargs | cut -d ' ' -f 2")
  CHILD_IP2=$(ssh -tt node2 "ifconfig | grep 'inet' | grep '10.10' | xargs | cut -d ' ' -f 2")
  set_worker_ips "$LOCAL_IP" "$CHILD_IP1" "$CHILD_IP2"
  ssh -tt node1 "$(declare -f set_worker_ips); set_worker_ips $LOCAL_IP $CHILD_IP1 $CHILD_IP2"
  ssh -tt node2 "$(declare -f set_worker_ips); set_worker_ips $LOCAL_IP $CHILD_IP1 $CHILD_IP2"
}

path_add() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="${PATH:+"$PATH:"}$1"
    echo "export PATH=$PATH" >>~/.bashrc
  fi
}

format_and_start_dfs() {
  cd /mnt/data/hadoop-3.3.4/ || {
    echo 'Failed to find /mnt/data/hadoop-3.3.4'
    exit 1
  }
  path_add /mnt/data/hadoop-3.3.4/bin
  ssh -tt node1 "$(declare -f path_add); path_add /mnt/data/hadoop-3.3.4/bin"
  ssh -tt node2 "$(declare -f path_add); path_add /mnt/data/hadoop-3.3.4/bin"
  path_add /mnt/data/hadoop-3.3.4/sbin
  ssh -tt node1 "$(declare -f path_add); path_add /mnt/data/hadoop-3.3.4/sbin"
  ssh -tt node2 "$(declare -f path_add); path_add /mnt/data/hadoop-3.3.4/sbin"
  # shellcheck disable=SC1090
  source ~/.bashrc || {
    echo "Cannot re-source ~/.bashrc"
    exit 1
  }
  hdfs namenode -format
  start-dfs.sh
}

kill_all_process() {
  for x in $(jps | awk '{print $1}') ; do kill -9 "$x" ; done
}

main() {
  kill_all_process
  ssh -tt node1 "$(declare -f kill_all_process); kill_all_process"
  ssh -tt node2 "$(declare -f kill_all_process); kill_all_process"

  java_install_all
  mount_disk_all "$1"
  apache_download_all
  set_hdfs_ip_conf_all
  set_hdfs_dirs_conf_all
  set_java_path_all
  set_worker_ips_all
  format_and_start_dfs
}

case $1 in
1) java_install_all ;;
2) mount_disk_all "$2" ;;
3) apache_download_all ;;
4) set_hdfs_ip_conf_all ;;
5) set_hdfs_dirs_conf_all ;;
6) set_java_path_all ;;
7) set_worker_ips_all ;;
8) format_and_start_dfs ;;
all)
  echo "Executing all"
  main "$2"
  ;;
*) echo "Unexpected option $1" ;;
esac
