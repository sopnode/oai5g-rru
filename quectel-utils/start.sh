#!/bin/bash
# This script requires below environment variables
# INTERFACE -- interface name which it will configure
# DNN0 -- dnn of the first PDU session
# DNN_TYPE0 -- dnn type of the first pdu session
# DNN1 -- dnn of the second PDU session
# DNN_TYPE1 -- dnn type of the second pdu session
# IPERF_SERVER -- iperf server to use for iperf test

set -euo pipefail

#DEFAULT DNN PARAMETERs
DEFAULT_DNN0=oai.ipv4
#DEFAULT_DNN1=ims
quiet=false # if quiet is false then resume with ping test

# handle optional options
while getopts F:S:q option; do
    case "${option}"
    in
        F) dnn0=${OPTARG};;
        S) dnn1=${OPTARG};;
        q) quiet=true;;
        \?) exit 1;;
    esac
done
if [ -z ${dnn0+x} ]; then
    DNN0=$DEFAULT_DNN0
else
    DNN0=$dnn0
fi
if [ -z ${dnn1+x} ]; then
    if [ -z ${DNN1+x} ]; then
	echo "DNN1 is unset"
    else
	DNN1=$DEFAULT_DNN1
    fi
    echo "running $0 with parameters: DNN0=$DNN0, no DNN1, quiet $quiet"
else
    DNN1=$dnn1
    echo "running $0 with parameters: DNN0=$DNN0, DNN1=$DNN1, quiet $quiet"
fi

#If double pdu is not needed remove DNN1 variable
DNN_TYPE0=${DNN_TYPE0:-ipv4}
DNN_TYPE1=${DNN_TYPE1:-ipv4v6}
INTERFACE=${INTERFACE:-wwan0}
DEVICE=/dev/cdc-wdm0

echo "-------Setting up $INTERFACE for testing-------"
ifconfig $INTERFACE up

if [[ -v DNN1 ]]; then echo "---- ip link add link wwan0 name ${INTERFACE}.1 type vlan id 1"; fi
if [[ -v DNN1 ]]; then ip link add link wwan0 name $INTERFACE.1 type vlan id 1; fi
if [[ -v DNN1 ]]; then echo "---- ip link set ${INTERFACE}.1 up"; fi
if [[ -v DNN1 ]]; then ip link set $INTERFACE.1 up; fi

echo "---- mbimcli -p -d ${DEVICE} --set-radio-state=on"
mbimcli -p -d $DEVICE --set-radio-state=on
sleep 2
echo "---- mbimcli -p -d ${DEVICE} --attach-packet-service"
mbimcli -p -d $DEVICE --attach-packet-service
echo "---- mbimcli -p -d ${DEVICE} --connect=session-id=0,apn=${DNN0},ip-type=${DNN_TYPE0}"
mbimcli -p -d $DEVICE --connect=session-id=0,apn=$DNN0,ip-type=$DNN_TYPE0
echo "---- mbim-set-ip.sh ${DEVICE} ${INTERFACE} 0"
mbim-set-ip.sh $DEVICE $INTERFACE 0

if [[ -v DNN1 ]]; then echo "---- mbimcli -p -d ${DEVICE} --connect=session-id=1,apn=${DNN1},ip-type=${DNN_TYPE1}"; fi
if [[ -v DNN1 ]]; then mbimcli -p -d $DEVICE --connect=session-id=1,apn=$DNN1,ip-type=$DNN_TYPE1; fi
if [[ -v DNN1 ]]; then echo "---- mbim-set-ip.sh ${DEVICE} ${INTERFACE}.1 1"; fi
if [[ -v DNN1 ]]; then mbim-set-ip.sh $DEVICE $INTERFACE.1 1; fi

DNN0_IPADDRESS=$(ip -f inet addr show $INTERFACE | awk '/inet / {print $2}')
if [[ -v DNN1 ]]; then DNN1_IPADDRESS=$(ip -f inet addr show $INTERFACE.1 | awk '/inet / {print $2}'); fi

if  [[ $quiet = "false" ]] ; then
    echo "--------Perform Ping Test --------"
    if [[ -v DNN0_IPADDRESS ]]; then ping -I $INTERFACE -c 4 8.8.8.8 ; fi
    if [[ -v DNN1_IPADDRESS ]]; then ping -I $INTERFACE.1 -c 4 8.8.8.8 ; fi
fi
