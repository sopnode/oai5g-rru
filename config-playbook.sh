#!/bin/bash

#
# This script modifies the ansible playbook to handle various worker nodes (R2lab FIT and/or PC nodes)
#

function usage() {
    echo "USAGE:"
    echo "config-playbook.sh fit-nodes pc-nodes"
    exit 1
}


if [ $# -eq 0 ]; then
    echo "Error, no worker node provided"
    usage
fi


DIR="/root/SLICES/sopnode/ansible/inventories/sopnode_r2lab"

IP_FIT_PREFIX="192.168.3."
IP_PC_PREFIX="192.168.3.6"

items=""

for WORKER in "$@"
do
    case "$WORKER" in
	pc01|pc02)
	    id=${WORKER#"pc0"}
	    IP="$IP_PC_PREFIX$id"
	    echo "handling $WORKER IP: $IP"
	    ;;
	fit*)
	    id=${WORKER#"fit"}
	    IP="$IP_FIT_PREFIX"$((id+0))
	    echo "handling $WORKER $IP"
	    ;;
	*)
	    echo "Error, unknown worker $WORKER"
	    usage
	    ;;
    esac
    items=$items"        $IP:\n"
    items=$items"          xx-name: $WORKER\n"
done
cp $DIR/generic/hosts $DIR/cluster/hosts
perl -i -pe "BEGIN{undef $/;} s/WORKER_ITEMS\n/$items/smg" $DIR/cluster/hosts
echo "Configuring Ansible playbook $DIR/hosts:"
diff $DIR/generic/hosts $DIR/cluster/hosts



