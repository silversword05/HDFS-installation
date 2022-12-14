#!/bin/bash
trap "exit" INT

# Fill configurations here
MASTER=(22 amondal5@c220g2-011320.wisc.cloudlab.us)
CHILD1=(22 amondal5@c220g2-011319.wisc.cloudlab.us)
CHILD2=(22 amondal5@c220g2-011315.wisc.cloudlab.us)

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
