#!/bin/bash
# This script requires below environment variables
# DNN1 -- dnn of the second PDU session

DEVICE=/dev/cdc-wdm0
INTERFACE=${INTERFACE:-wwan0}
#DNN1=ims
echo "---- mbimcli -d ${DEVICE} -p --disconnect=0"
## Problem with oai-gnb develop branch can not do PDU session release meanwhile we don't do PDU session release
#mbimcli -d $DEVICE -p --disconnect=0
if [[ -v DNN1 ]]; then echo "---- mbimcli -d ${DEVICE} -p --disconnect=1"; fi
## Problem with oai-gnb develop branch can not do PDU session release meanwhile we don't do PDU session release
#if [[ -v DNN1 ]]; then mbimcli -d $DEVICE -p --disconnect=1; fi
if [[ -v DNN1 ]]; then echo "---- ip link set ${INTERFACE}.1 down"; fi
if [[ -v DNN1 ]]; then ip link set $INTERFACE.1 down; fi
if [[ -v DNN1 ]]; then echo "---- ip link del link wwan0 name ${INTERFACE}.1 type vlan id 1"; fi
if [[ -v DNN1 ]]; then ip link del link wwan0 name $INTERFACE.1 type vlan id 1; fi
echo "---- mbimcli -p -d ${DEVICE} --set-radio-state=off"
mbimcli -p -d $DEVICE --set-radio-state=off

echo "-------Removing the $INTERFACE -------"
ifconfig $INTERFACE down
