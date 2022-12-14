#!/bin/bash
trap "exit" INT

# Fill configurations here
MASTER=(<master-port> <username>@<master-machine-name>)
CHILD1=(<child1-port> <username>@<child1-machine-name>)
CHILD2=(<child2-port> <username>@<child2-machine-name>)

# Generate master key
MASTER_COMMAND="ssh-keygen -t rsa -q -N '' <<< $'\ny'; echo '\n'; cat ~/.ssh/id_rsa.pub;"
MASTER_KEY=$(ssh -tt -o StrictHostKeyChecking=no -p "${MASTER[0]}" "${MASTER[1]}" "${MASTER_COMMAND}" | grep "ssh-rsa")
echo "Master key generated"
echo "$MASTER_KEY"

# Adding master key to all nodes
ADD_AUTHORIZED_KEYS="echo ${MASTER_KEY} >> ~/.ssh/authorized_keys"
ssh -tt -o StrictHostKeyChecking=no -p "${MASTER[0]}" "${MASTER[1]}" "${ADD_AUTHORIZED_KEYS}"
ssh -tt -o StrictHostKeyChecking=no -p "${CHILD1[0]}" "${CHILD1[1]}" "${ADD_AUTHORIZED_KEYS}"
ssh -tt -o StrictHostKeyChecking=no -p "${CHILD2[0]}" "${CHILD2[1]}" "${ADD_AUTHORIZED_KEYS}"
