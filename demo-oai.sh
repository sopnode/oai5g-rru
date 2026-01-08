#!/bin/bash

usage() {
    echo "USAGE:"
    echo "demo-oai.sh start |"
    echo "            stop |"
    echo "            configure-all |"
    echo "            start-cn |"
    echo "            start-flexric |"
    echo "            start-gnb |"
    echo "            start-nr-ue |"
    echo "            start-nr-ue2 |"
    echo "            start-nr-ue3 |"
    echo "            stop-cn |"
    echo "            stop-flexric |"
    echo "            stop-gnb |"
    echo "            stop-nr-ue |"
    echo "            stop-nr-ue2 |"
    echo "            stop-nr-ue3 |"
    exit 1
}


#################################################################################
#################################################################################
# Following parameters automatically set by configure-demo-oai.sh script
# do not change them here !
NS="@DEF_NS@" # k8s namespace
NODE_AMF_UPF="@DEF_NODE_AMF_UPF@" # node in wich run amf and upf pods
export NODE_GNB="@DEF_NODE_GNB@" # node in which gnb pod runs
export RRU="@DEF_RRU@" # in ['b210', 'n300', 'n320', 'jaguar', 'panther', 'rfsim']
RUN_MODE="@DEF_RUN_MODE@" # in ['full', 'gnb-only', 'gnb-upf']
GNB_MODE="@DEF_GNB_MODE@" # in ['monolithic', 'cudu', 'cucpup']
export LOGS="@DEF_LOGS@" # boolean, true if logs are retrieved on pods
export PCAP="@DEF_PCAP@" # boolean, true if pcap are generated on pods
MONITORING="@DEF_MONITORING@" # boolean, true if prometheus metrics parser is generated on oai-gnb pod (monolithic)
export FLEXRIC="@DEF_FLEXRIC@" # boolean, true if flexRIC is included
#
export MCC="@DEF_MCC@"
export MNC="@DEF_MNC@"
export TAC="@DEF_TAC@"
export DNN0="@DEF_DNN0@"
export DNN0_PDU_TYPE="@DEF_DNN0_PDU_TYPE@"
export DNN1="@DEF_DNN1@"
export DNN1_PDU_TYPE="@DEF_DNN1_PDU_TYPE@"
export SLICE1_SST="@DEF_SLICE1_SST@"
export SLICE1_SD="@DEF_SLICE1_SD@"
SLICE1_5QI="@DEF_SLICE1_5QI@"
SLICE1_UPLINK="@DEF_SLICE1_UPLINK@"
SLICE1_DOWNLINK="@DEF_SLICE1_DOWNLINK@"
export SLICE2_SST="@DEF_SLICE2_SST@"
export SLICE2_SD="@DEF_SLICE2_SD@"
SLICE2_5QI="@DEF_SLICE2_5QI@"
SLICE2_UPLINK="@DEF_SLICE2_UPLINK@"
SLICE2_DOWNLINK="@DEF_SLICE2_DOWNLINK@"
export GNB_ID="@DEF_GNB_ID@"
#
################SST0="@DEF_SST0@"
FULL_KEY="@DEF_FULL_KEY@"
OPC="@DEF_OPC@"
RFSIM_IMSI="@DEF_RFSIM_IMSI@"
RFSIM_IMSI_UE2="@DEF_RFSIM_IMSI_UE2@"
RFSIM_IMSI_UE3="@DEF_RFSIM_IMSI_UE3@"
#
PREFIX_DEMO="@DEF_PREFIX_DEMO@" # Directory in which all scripts will be copied on the k8s server to run the demo
#
#################################################################################
##################################################################################
TMP="/tmp/tmp.$USER"
mkdir -p "$TMP"
PREFIX_STATS="$TMP/oai5g-stats"
OAISA_REPO="docker.io/oaisoftwarealliance"

# Interfaces names of VLANs in sopnode servers
# Local network interface is defined in prepare-demo-oai.sh ("net-30" for sopnode-{l1|w1})
IF_NAME_N2N3_DEFAULT="@DEF_LOCAL_INTERFACE@" 
IF_NAME_N6_DEFAULT="@DEF_LOCAL_INTERFACE@" 
IF_NAME_E1_DEFAULT="@DEF_LOCAL_INTERFACE@" 
IF_NAME_E2_DEFAULT="@DEF_LOCAL_INTERFACE@" 
IF_NAME_F1_DEFAULT="@DEF_LOCAL_INTERFACE@"

IF_NAME_VLAN_N300_1="r2lab_usrp"
IF_NAME_VLAN_N300_2="r2lab_usrp"
IF_NAME_VLAN_N320_1="r2lab_usrp"
IF_NAME_VLAN_N320_2="r2lab_usrp"
IF_NAME_VLAN_JAGUAR="r2lab_aw2s"
IF_NAME_VLAN_PANTHER="r2lab_aw2s"
IF_NAME_VLAN_BENETEL1="r2lab_benetel"



############# Running-mode dependent parameters configuration ###############
#

if [[ $RUN_MODE = "full" ]]; then
    # Local RAN, Local CN
    SUBNET_N2N3="192.168.3"
    SUBNET_N6="192.168.3"
    NETMASK_N2N3="24"
    NETMASK_N6="24"
    export IF_NAME_N2N3="$IF_NAME_N2N3_DEFAULT"
    IF_NAME_N6="$IF_NAME_N6_DEFAULT"
    #
    ENABLED_MYSQL=true
    #
    ENABLED_NRF=true
    NFS_NRF_HOST="oai-nrf"
    #
    ENABLED_NSSF=true
    #
    ENABLED_UDM=true
    NFS_UDM_HOST="oai-udm"
    ENABLED_UDR=true
    NFS_UDR_HOST="oai-udr"
    ENABLED_AUSF=true
    NFS_AUSF_HOST="oai-ausf"
    # amf chart
    ENABLED_AMF=true
    NFS_AMF_HOST="oai-amf"
    IF_N2="n2"
    MULTUS_AMF_N2="true"
    IP_AMF_N2="$SUBNET_N2N3.201"
    NETMASK_AMF_N2="$NETMASK_N2N3"
    GW_AMF_N2=""
    ROUTES_AMF_N2=""
    IF_NAME_AMF_N2="$IF_NAME_N2N3"
    # upf chart
    ENABLED_UPF=true
    NFS_UPF_HOST="oai-upf"
    IF_SBI="eth0"
    IF_N3="n3"
    IF_N4="eth0"
    IF_N6="eth0"
    ENABLE_SNAT="yes"
    MULTUS_UPF_N3="true"
    IP_UPF_N3="$SUBNET_N2N3.202"
    NETMASK_UPF_N3="$NETMASK_N2N3"
    GW_UPF_N3=""
    ROUTES_UPF_N3=""
    IF_NAME_UPF_N3="$IF_NAME_N2N3"
    MULTUS_UPF_N4="false"
    IP_UPF_N4="" 
    NETMASK_UPF_N4=""
    GW_UPF_N4=""
    ROUTES_UPF_N4=""
    IF_NAME_UPF_N4=""
    MULTUS_UPF_N6="true"
    IP_UPF_N6="$SUBNET_N6.207" 
    NETMASK_UPF_N6="$NETMASK_N6"
    GW_UPF_N6=""
    ROUTES_UPF_N6=""
    IF_NAME_UPF_N6="$IF_NAME_N6"
    # TS chart
    ENABLED_TS=true
    MULTUS_TS="$MULTUS_UPF_N6"
    IP_TS="$SUBNET_N6.208"
    NETMASK_TS="$NETMASK_N6"
    GW_TS=""
    IF_NAME_TS="$IF_NAME_N6"
    UPF_HOST="$IP_UPF_N6"
    NODE_TS="$NODE_AMF_UPF"
    # smf chart
    ENABLED_SMF=true
    NFS_SMF_HOST="oai-smf"
    MULTUS_SMF_N4="false"
    IP_SMF_N4="" 
    NETMASK_SMF_N4=""
    GW_SMF_N4=""
    ROUTES_SMF_N4=""
    IF_NAME_SMF_N4="" 
    IP_DNS1="138.96.0.210"
    IP_DNS2="193.51.196.138"
    # ran charts
    export HOST_AMF="$IP_AMF_N2"
    export MULTUS_GNB_N2="true"
    export IP_GNB_N2="$SUBNET_N2N3.203"
    export GNB_N2_IF_NAME="n2"
    export MULTUS_GNB_N3="false"
    if [[ $GNB_MODE = 'cucpup' ]]; then
	export F1IFNAME="f1c"
	export MULTUS_CUUP_N3="true"
	export IP_GNB_N3="$SUBNET_N2N3.204"
	export CUUP_N3_IF_NAME="n3"
	export IP_NRUE="$SUBNET_N2N3.205"
	export IP_NRUE2="$SUBNET_N2N3.206"
	export IP_NRUE3="$SUBNET_N2N3.207"
    else
	export F1IFNAME="f1"
	export IP_GNB_N3="$IP_GNB_N2"
	export IP_NRUE="$SUBNET_N2N3.204"
	export IP_NRUE2="$SUBNET_N2N3.205"
	export IP_NRUE3="$SUBNET_N2N3.206"
    fi
    GNB_N3_IF_NAME="n2"
	#
	# ** NRUE specific part **
	#
	export MULTUS_NRUE="true"
else
    # Local RAN, External MYSQL/UDR/UDM/AUSF/AMF/SMF
    ENABLE_SNAT="off" # "yes" or "off"
    if [[ $RUN_MODE = "gnb-upf" ]]; then
	# Local RAN and local UPF
	export SUBNET_N2N3="172.21.10"
	export NETMASK_N2N3="26"
	export IF_NAME_N2N3="br-slices"
	#
	export ENABLED_MYSQL=false
	export ENABLED_NRF=false
	export NFS_NRF_HOST="$SUBNET_N2N3.203"
	export ENABLED_NSSF=false
	export ENABLED_UDR=false
	export NFS_UDR_HOST="oai-udr"
	export ENABLED_UDM=false
	export NFS_UDM_HOST="oai-udm"
	export ENABLED_AUSF=false
	export NFS_AUSF_HOST="oai-ausf"
	# amf 
	export ENABLED_AMF=false
	export NFS_AMF_HOST="$SUBNET_N2N3.200"
	export IP_AMF_N2=""
	export IF_N2="" # unused
	# smf
	export ENABLED_SMF=false
	export NFS_SMF_HOST="$SUBNET_N2N3.202"
	# upf
	export ENABLED_UPF=true
	export NFS_UPF_HOST="oai-upf"
	export IF_SBI="n3"
	export IF_N3="n3"
	export IF_N4="n3"
	export IF_N6="eth0"
	export MULTUS_UPF_N3="true"
	export IP_UPF_N3="$SUBNET_N2N3.222"
	export NETMASK_UPF_N3="$NETMASK_N2N3"
	export GW_UPF_N3=""
	export ROUTES_UPF_N3="[{'dst': '10.8.0.0/24','gw': '172.21.10.254'}]"
	export IF_NAME_UPF_N3="$IF_NAME_N2N3"
	export MULTUS_UPF_N4="false"
	export IP_UPF_N4="" 
	export NETMASK_UPF_N4=""
	export GW_UPF_N4=""
	export ROUTES_UPF_N4=""
	export IF_NAME_UPF_N4=""
	export MULTUS_UPF_N6="false"
	export IP_UPF_N6="" 
	export NETMASK_UPF_N6=""
	export GW_UPF_N6=""
	export ROUTES_UPF_N6=""
	export IF_NAME_UPF_N6=""
	# TS
	export ENABLED_TS=false
	# ran charts
	export HOST_AMF="oai-amf"
	export MULTUS_GNB_N2="true"
	export IP_GNB_N2="$SUBNET_N2N3.223"
	export GNB_N2_IF_NAME="n2"
	export MULTUS_GNB_N3="false"
	if [[ $GNB_MODE = 'cucpup' ]]; then
	    export F1IFNAME="f1c"
	    export MULTUS_CUUP_N3="true"
	    export IP_GNB_N3="$SUBNET_N2N3.224"
	    export CUUP_N3_IF_NAME="n3"
	    export IP_NRUE="$SUBNET_N2N3.225"
	    export IP_NRUE2="$SUBNET_N2N3.226"
	    export IP_NRUE3="$SUBNET_N2N3.227"
	else
	    export F1IFNAME="f1"
	    export IP_GNB_N3="$IP_GNB_N2"
	    export IP_NRUE="$SUBNET_N2N3.224"
	    export IP_NRUE2="$SUBNET_N2N3.225"
	    export IP_NRUE3="$SUBNET_N2N3.226"
	fi
	export GNB_N3_IF_NAME="n2"
	export ROUTES_GNB_N2="" # Set the route for gNB to reach AMF (N2) and UPF (N3)
	#export ROUTES_GNB_N2="[{'dst': '172.21.0.0/16','gw': '192.168.128.129'},{'dst': '192.168.128.0/24','gw': '192.168.128.129'}]"
	#
	# ** NRUE specific part **
	#
	export MULTUS_NRUE="true"
    else
        # RUN_MODE=gnb-only
	# -- Local RAN and external CN
	#
        export SUBNET_N2N3="10.10.3" # "172.21.10"
        export HOST_AMF="$SUBNET_N2N3.200" #${NODE_AMF_UPF%"-v30"} # open5gs-amf service is unknown, use $NODE_AMF_UPF to set up external IP address # XXX "$SUBNET_N2N3.201"
        #export HOST_AMF=${NODE_AMF_UPF}
	#
	# ** GNB specific part (also used for CU) **
	#
	export MULTUS_GNB_N2="false"
	export IP_GNB_N2="$SUBNET_N2N3.205" # "$SUBNET_N2N3.223" 
        # Set the route to reach AMF
        export ROUTES_GNB_N2="" # [{'dst': '172.22.10.0/24','gw': '10.0.20.1'}]"
	export GNB_N2_IF_NAME="n3" # local pod network interface name for N2 (eth0 or n2 or n3)
	#
	export MULTUS_GNB_N3="true"
	export IP_GNB_N3="$IP_GNB_N2" # "$SUBNET_N2N3.224"
	export GNB_N3_IF_NAME="$GNB_N2_IF_NAME" # pod network interface name for N3 (eth0 or n2/n3)
	export NETMASK_N2N3="24"
        export IF_NAME_N2N3="n3br" # host interface used for multus on N2/N3 
	#
	#if [[ $GNB_MODE = 'cucpup' ]]; then
	#    export IP_GNB_N3="$SUBNET_N2N3.224"
	#    export IP_NRUE="$SUBNET_N2N3.225"
	#else
	#    export IP_GNB_N3="$IP_GNB_N2"
	#    export IP_NRUE="$SUBNET_N2N3.224"
	#fi
	#
	# ** CU-CP specific part **
	#
	export MULTUS_CUCP_N2="true"
	export IP_CUCP_N2="$IP_GNB_N2"
	export CUCP_N2_IF_NAME="n2"
	#
	# ** CU-UP specific part **
	#
	export MULTUS_CUUP_N3="true"
	export IP_CUUP_N3="$SUBNET_N2N3.206"
	export CUUP_N3_IF_NAME="n3"
	#
	# ** NRUE specific part **
	#
	export MULTUS_NRUE="false"
    fi
fi



############################### oai-cn5g chart parameters ########################
#
OAI5G_CHARTS="$PREFIX_DEMO/charts"
OAI5G_CORE="$OAI5G_CHARTS/oai-5g-core"
OAI5G_BASIC="$OAI5G_CORE/oai-5g-basic"
OAI5G_ADVANCE="$OAI5G_CORE/oai-5g-advance"

export CN_DEFAULT_GW=""

################################ oai-gnb chart parameters ########################
OAI5G_RAN="$OAI5G_CHARTS/oai-5g-ran"
R2LAB_REPO="docker.io/r2labuser"
MY_REPO="ghcr.io/ziyad-mabrouk/openairinterface5g"

# Default charts repo & tag

export RAN_TAG="2025.w34" # starting from w29 includes "Initial support for RedCap" feature in gNB
export GNB_NAME="gNB-r2lab"
export GNB_PULL_POLICY="IfNotPresent"

# DU/CU SPLIT parameters
#
export NODE_CU="$NODE_GNB" # same node used for cu/cu-cp/cu-up and du

########## DU specific part ##############
#DU_REPO="${R2LAB_REPO}/oai-gnb" DU_REPO must be GNB_REPO to handle aw2s case
export DU_TAG=${RAN_TAG}
export NAME_DU_SA="oai-du-sa"
#
export MULTUS_DU_F1C="true"
export IP_DU_F1C="172.21.6.90"
export NETMASK_DU_F1C="22"
export ROUTES_DU_F1C=""
export IF_NAME_DU_F1C="$IF_NAME_F1_DEFAULT"
#
export MULTUS_DU_F1U="true"
export IP_DU_F1U="172.21.16.90"
export NETMASK_DU_F1U="22"
export GW_DU_F1U=""
export ROUTES_DU_F1U=""
export IF_NAME_DU_F1U="$IF_NAME_F1_DEFAULT"
#
export MULTUS_DU_F1="true"
export IP_DU_F1="172.21.16.100"
export NETMASK_DU_F1="22"
export GW_DU_F1=""
export ROUTES_DU_F1=""
export IF_NAME_DU_F1="$IF_NAME_F1_DEFAULT"
#
export MULTUS_DU_E2="true"
export IP_DU_E2="192.168.85.91"
export NETMASK_DU_E2="24"
export GW_DU_E2=""
export ROUTES_DU_E2="" 
export IF_NAME_DU_E2="$IF_NAME_E2_DEFAULT"
#
export NAME_DU="oai-du"
export QOS_DU_DEF="true"
export NODE_DU="$NODE_GNB"
#
########## CU specific part ##############
export CU_REPO="${R2LAB_REPO}/oai-gnb" 
export CU_TAG=${RAN_TAG}
export NAME_CU_SA="oai-cu-sa"
#
export MULTUS_CU_F1="true"
export IP_CU_F1="172.21.16.92"
export NETMASK_CU_F1="22"
export GW_CU_F1="" 
export ROUTES_CU_F1="" 
export IF_NAME_CU_F1="$IF_NAME_F1_DEFAULT"
#
export MULTUS_CU_N2=${MULTUS_CU_N2:=$MULTUS_GNB_N2}
export IP_CU_N2=${IP_CU_N2:=$IP_GNB_N2}
export NETMASK_CU_N2=${NETMASK_CU_N2:=$NETMASK_N2N3}
export GW_CU_N2=${GW_CU_N2:=""}
export ROUTES_CU_N2=${ROUTES_CU_N2:=""}
export IF_NAME_CU_N2=${IF_NAME_CU_N2:=$IF_NAME_N2N3}
#
export MULTUS_CU_N3=${MULTUS_CU_N3:=$MULTUS_GNB_N3}
export IP_CU_N3=${IP_CU_N3:=$IP_GNB_N3}
export NETMASK_CU_N3=${NETMASK_CU_N3:=$NETMASK_N2N3}
export GW_CU_N3=${GW_CU_N3:=""}
export ROUTES_CU_N3=${ROUTES_CU_N3:=""}
export IF_NAME_CU_N3=${IF_NAME_CU_N3:=$IF_NAME_N2N3}
#
export MULTUS_CU_E2="true"
export IP_CU_E2="192.168.85.93"
export NETMASK_CU_E2="24"
export GW_CU_E2=""
export ROUTES_CU_E2="" 
export IF_NAME_CU_E2="$IF_NAME_E2_DEFAULT"
#
export ADD_OPTIONS_CU="--log_config.global_log_options level,nocolor,time"
export NAME_CU="oai-cu"
export QOS_CU_DEF="true"
# NODE_CU is defined above and also the same for CUCP/CUUP
#
########## CU-CP specific part ##############
export CUCP_REPO="${R2LAB_REPO}/oai-gnb" 
export CUCP_TAG=${RAN_TAG}
export NAME_CUCP_SA="oai-cu-cp-sa"
#
export MULTUS_CUCP_E1="true"
export IP_CUCP_E1="192.168.18.12"
export NETMASK_CUCP_E1="24"
export GW_CUCP_E1=""
export ROUTES_CUCP_E1=""
export IF_NAME_CUCP_E1="$IF_NAME_E1_DEFAULT"
#
export MULTUS_CUCP_E2="true"
export IP_CUCP_E2="192.168.85.93"
export NETMASK_CUCP_E2="24"
export GW_CUCP_E2=""
export ROUTES_CUCP_E2="" 
export IF_NAME_CUCP_E2="$IF_NAME_E2_DEFAULT"
#
export MULTUS_CUCP_N2=${MULTUS_CUCP_N2:=$MULTUS_GNB_N2}
export IP_CUCP_N2=${IP_CUCP_N2:=$IP_GNB_N2} 
export NETMASK_CUCP_N2=${NETMASK_CUCP_N2:=$NETMASK_N2N3}
export GW_CUCP_N2=${GW_CUCP_N2:=""}
export ROUTES_CUCP_N2=${ROUTES_CUCP_N2:=""}
export IF_NAME_CUCP_N2=${IF_NAME_CUCP_N2:=$IF_NAME_N2N3}
export CUCP_N2_IF_NAME=${CUCP_N2_IF_NAME:=$GNB_N2_IF_NAME}
#
export MULTUS_CUCP_F1C="true"
export IP_CUCP_F1C="172.21.16.92"
export NETMASK_CUCP_F1C="22"
export GW_CUCP_F1C=""
export ROUTES_CUCP_F1C=""
export IF_NAME_CUCP_F1C="$IF_NAME_F1_DEFAULT"
#
export ADD_OPTIONS_CUCP="--log_config.global_log_options level,nocolor,time"
export NAME_CUCP="oai-cu-cp"
export QOS_CUCP_DEF="true"
export NODE_CUCP="$NODE_CU"
#
########## CU-UP specific part ##############
export CUUP_REPO="$R2LAB_REPO/oai-nr-cuup"
export CUUP_TAG=${RAN_TAG}
export NAME_CUUP_SA="oai-cu-up-sa"
#
export MULTUS_CUUP_E1="true"
export IP_CUUP_E1="192.168.18.13"
export NETMASK_CUUP_E1="24"
export GW_CUUP_E1=""
export ROUTES_CUUP_E1="" 
export IF_NAME_CUUP_E1="$IF_NAME_E1_DEFAULT"
#
export MULTUS_CUUP_E2="true"
export IP_CUUP_E2="192.168.85.92"
export NETMASK_CUUP_E2="24"
export GW_CUUP_E2=""
export ROUTES_CUUP_E2="" 
export IF_NAME_CUUP_E2="$IF_NAME_E2_DEFAULT"
#
export MULTUS_CUUP_N3=${MULTUS_CUUP_N3:=$MULTUS_GNB_N3}
export IP_CUUP_N3=${IP_CUUP_N3:=$IP_GNB_N3}
export NETMASK_CUUP_N3=${NETMASK_CUUP_N3:=$NETMASK_N2N3}
export GW_CUUP_N3=${GW_CUUP_N3:=""}
export ROUTES_CUUP_N3=${ROUTES_CUUP_N3:=""}
export IF_NAME_CUUP_N3=${IF_NAME_CUUP_N3:=$IF_NAME_N2N3}
export CUUP_N3_IF_NAME=${CUUP_N3_IF_NAME:=$GNB_N2_IF_NAME}
#
export MULTUS_CUUP_F1U="true"
export IP_CUUP_F1U="172.21.16.93"
export NETMASK_CUUP_F1U="22"
export GW_CUUP_F1U="" # "172.21.19.254"
export ROUTES_CUUP_F1U=""
export IF_NAME_CUUP_F1U="$IF_NAME_F1_DEFAULT"  
#
export ADD_OPTIONS_CUUP=""
export NAME_CUUP="oai-cuup"
export HOST_CUCP="$IP_CUCP_E1"   #"oai-cu"
export QOS_CUUP_DEF="true"
export NODE_CUUP="$NODE_CU"

if [[ $GNB_MODE = 'cucpup' ]]; then
    export CU_HOST_FROM_DU="$IP_CUCP_F1C"
    export CU_HOST_FROM_CUUP="$IP_CUCP_E1"
else
    export CU_HOST_FROM_DU="$IP_CU_F1"
fi
#
########## GNB Monolithic specific part ################
#
export NETMASK_GNB_N2="$NETMASK_N2N3"
export NETMASK_GNB_N3="$NETMASK_N2N3"
export NETMASK_GNB_RU="24"
#
export MULTUS_GNB_E2="true"
export IP_GNB_E2="192.168.85.94"
export NETMASK_GNB_E2="24"
export GW_GNB_E2=""
export ROUTES_GNB_E2="" 
export IF_NAME_GNB_E2="$IF_NAME_E2_DEFAULT"
################## RRU-dependent part ###################
#
RU_MODE="static" # in ['static', 'dhcp']
#
#### rfsim RU case ####
GNB_REPO_rfsim="${R2LAB_REPO}/oai-gnb"
GNB_TAG_rfsim="${RAN_TAG}"
CONF_rfsim="gnb.sa.band78.106prb.rfsim.conf" 
CONF_DU_rfsim="du.sa.band78.106prb.rfsim.conf" 
OPTIONS_rfsim="-E --rfsim --log_config.global_log_options level,nocolor,time"
#
#### b2xx RU case ####
GNB_REPO_b2xx="${R2LAB_REPO}/oai-gnb"
GNB_TAG_b2xx="${RAN_TAG}"
CONF_b210="gnb.sa.band78.fr1.106PRB.usrpb210.conf"
OPTIONS_b2xx="-E --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"

#### n3xx RU case ####
GNB_REPO_n3xx="${R2LAB_REPO}/oai-gnb"
GNB_TAG_n3xx="${RAN_TAG}"
#
CONF_n320="gnb.sa.band78.106prb.n310.7ds2u.conf"
CONF_DU_n320="du.sa.band78.106prb.n310.7ds2u.conf"
CONF_n300="$CONF_n320"
CONF_DU_n300="$CONF_DU_n320"
OPTIONS_n3xx="--usrp-tx-thread-config 1 --tune-offset 30000000 --MACRLCs.[0].ul_max_mcs 14 --L1s.[0].max_ldpc_iterations 4 --log_config.global_log_options level,nocolor,time"
#
if [[ $RU_MODE = "dhcp" ]]; then
    IP_GNB_N300_1="dhcp"
    IP_GNB_N300_2="dhcp"
    IP_GNB_N320_1="dhcp"
    IP_GNB_N320_2="dhcp"
else
    IP_GNB_N300_1="192.168.235.120" # @IP N300.1 + 17
    IP_GNB_N300_2="192.168.235.121" # @IP N300.2 + 17
    IP_GNB_N320_1="$IP_GNB_N300_1"
    IP_GNB_N320_2="$IP_GNB_N300_2"
fi
MTU_n3xx="9000"
ADDRS_n300="addr=192.168.235.103,second_addr=192.168.235.104"
ADDRS_n320="addr=192.168.235.105" #",second_addr=192.168.235.106"

#### aw2s RU case ####
GNB_REPO_aw2s="${R2LAB_REPO}/oai-gnb-aw2s"
GNB_TAG_aw2s="${RAN_TAG}"
#
CONF_jaguar="gnb.sa.band78.133prb.aw2s.ddsuu.50MHz.conf"
CONF_DU_jaguar="du.sa.band78.133prb.aw2s.ddsuu.50MHz.conf"
CONF_panther="gnb.sa.band78.51prb.aw2s.ddsuu.20MHz.1x1.conf" # to test with redcap qhats based on RG255C-GL (qhat20/21/22/23)
CONF_DU_panther="${CONF_DU_jaguar}"
OPTIONS_aw2s="--thread-pool 9,11,13,15,17,19,21,23 --log_config.global_log_options level,nocolor,time"
if [[ $RU_MODE = "dhcp" ]]; then
    export IP_GNB_jaguar="dhcp"
    export IP_GNB_panther="dhcp"
else
    export IP_GNB_jaguar="192.168.236.104" # @IP ADDR_jaguar + 3
    export IP_GNB_panther="192.168.236.106" # @IP ADDR_panther + 3
fi
export ADDR_jaguar="192.168.236.101" 
export ADDR_panther="192.168.236.103" 

#### benetel RU case ####
export TYPE_N2="macvlan"
export MODE_N2="bridge"
export TYPE_N3="macvlan"
export MODE_N3="bridge"

GNB_REPO_benetel="${OAISA_REPO}/oai-gnb-fhi72"
GNB_TAG_benetel="2025.w50"

#CONF_benetel1="gnb.sa.band78.273prb.fhi72.4x4-benetel550-ci-scripts.conf"
CONF_DU_benetel1="du.sa.band78.273prb.fhi72.4x4-benetel550.conf"
#CONF_benetel2="${CONF_benetel1}"
#CONF_DU_benetel2="${CONF_DU_benetel1}"
OPTIONS_benetel="--log_config.global_log_options level,nocolor,time"
if [[ $RU_MODE = "dhcp" ]]; then
    export IP_GNB_benetel1="dhcp"
    export IP_GNB_benetel2="dhcp"
else
    export IP_GNB_benetel1="192.168.233.104" # @IP ADDR_jaguar + 3
    export IP_GNB_benetel2="192.168.233.105" # @IP ADDR_panther + 3
fi
MTU_benetel="9216"
MAC_UPLANE1="00:11:22:33:44:66"
MAC_CPLANE1="00:11:22:33:44:67"
SRIOV_NS="sriov-network-operator"
VLAN_benetel1="801"
VLAN_benetel2="802"
ADDR_benetel1="192.168.233.101" 
ADDR_benetel2="192.168.233.102"
MAC_benetel1="8c:1f:64:d1:12:8c"
MAC_benetel2="8c:1f:64:d1:12:50"
DPDK_VF_U="0000:3a:09.0" # for sopnode-f3 U_PLANE
DPDK_VF_C="0000:3a:09.1" # for sopnode-f3 C_PLANE



########################### oai-nr-ue rfsim chart parameters #####################
NRUE_REPO="${R2LAB_REPO}/oai-nr-ue"
#NRUE_REPO="${OAISA_REPO}/oai-nr-ue"
NRUE_TAG="${RAN_TAG}"
OPTIONS_NRUE="--rfsim -C 3619200000 -r 106 --numerology 1 --ssb 516 -E  --log_config.global_log_options level,nocolor,time" 
#OPTIONS_NRUE="--sa --rfsim -C 3619200000 -r 106 --numerology 1 --ssb 516 -E  --log_config.global_log_options level,nocolor,time" 
NETMASK_NRUE="$NETMASK_N2N3"
export IF_NAME_NRUE="$IF_NAME_N2N3"
NRUE_USRP="rfsim"

########################### oai-flexric chart parameters #####################
FLEXRIC_REPO="ghcr.io/ziyad-mabrouk/oai-flexric"
#FLEXRIC_REPO="oaisoftwarealliance/oai-flexric"
export FLEXRIC_TAG="test"
#FLEXRIC_TAG="latest"
export FLEXRIC_PULL_POLICY="Always"
export HOST_FLEXRIC="oai-flexric"


########################### sopnode-f3 specific tuning #####################

if [[ "$NODE_GNB" == "sopnode-f3" ]]; then
  echo "Configuring core affinity for sopnode-f3..."

  # Set new AW2S options
  OPTIONS_aw2s="--thread-pool 48,50,52,54,56,58,60,62 --log_config.global_log_options level,nocolor,time"

  # Path to the gNB config file
  CONF_FILE="$PREFIX_DEMO/oai5g-rru/ran-config/conf/$CONF_jaguar"

  if [[ -f "$CONF_FILE" ]]; then
    echo "Patching $CONF_FILE..."

    # Replace rxfh_core_id
    sed -i 's/^\s*rxfh_core_id\s*=.*/        rxfh_core_id   = 48;/' "$CONF_FILE"

    # Replace txfh_core_id
    sed -i 's/^\s*txfh_core_id\s*=.*/        txfh_core_id   = 50;/' "$CONF_FILE"

    # Replace tp_cores
    sed -i 's/^\s*tp_cores\s*=.*/        tp_cores       = [52,54,56,58,60,62,96,98];/' "$CONF_FILE"

    # Replace num_tp_cores
    sed -i 's/^\s*num_tp_cores\s*=.*/        num_tp_cores   = 8;/' "$CONF_FILE"
  else
    echo "Warning: Config file $CONF_FILE not found."
  fi
fi


##################################################################################

# Generate unique MAC addresses for multus interfaces in oai5g pods
gener-mac()
{
    CPTfile="$TMP/cpt-$$.dat"
    PREFIXfile="$TMP/prefix-$$.dat"
    if [ ! -f "$CPTfile" ]; then
	CPT=0
    else
	CPT=$(cat "$CPTfile")
    fi
    if [ ! -f "$PREFIXfile" ]; then
	# GNB_ID should be of following format "0x1234", use this as MAC prefix
	if [[ ${GNB_ID:0:2} == "0x" ]] ; then
	    PREFIX="${GNB_ID:2:2}:${GNB_ID:4:2}:"
	else
	    PREFIX="12:34:"
	fi
	PREFIX="12:34:00:"
	case $NODE_AMF_UPF in
	    "sopnode-l1-v30")
		PREFIX=$PREFIX"00:";;
	    "sopnode-w1-v30")
		PREFIX=$PREFIX"01:";;
	    *)  PREFIX=$PREFIX"02:";;
	esac
	case $NODE_GNB in
	    "sopnode-l1-v30")
		PREFIX=$PREFIX"00:";;	
	    "sopnode-w1-v30")
		PREFIX=$PREFIX"01:";;	
	    *)  PREFIX=$PREFIX"02:";;
	esac
	echo "${PREFIX}" > "$PREFIXfile"
    else
	PREFIX=$(cat "$PREFIXfile")
    fi
    (( CPT++ ))
    echo "${CPT}" > "$CPTfile"
    SUFFIX=$(printf "%02x" $CPT)
    echo "$PREFIX$SUFFIX"
}

#################################################################################

configure-oai-5g-@mode@() {

    # if $LOGS is true, create a tcpdump container with privileges
    # if $PCAP is true, start tcpdump and create a shared volume to store pcap
    echo "Configuring chart $OAI5G_@MODE@/values.yaml for R2lab"
    cat > "$TMP"/@mode@-values.sed <<EOF
s|@PRIVILEGED@|$LOGS|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@START_TCPDUMP@|$PCAP|
s|@SHAREDVOLUME@|$PCAP|
s|@IP_NRF@|$NFS_NRF_HOST|
s|@ENABLED_MYSQL@|$ENABLED_MYSQL|
s|@ENABLED_NRF@|$ENABLED_NRF|
s|@ENABLED_NSSF@|$ENABLED_NSSF|
s|@ENABLED_UDR@|$ENABLED_UDR|
s|@ENABLED_UDM@|$ENABLED_UDM|
s|@ENABLED_AUSF@|$ENABLED_AUSF|
s|@ENABLED_AMF@|$ENABLED_AMF|
s|@CN_DEFAULT_GW@|$CN_DEFAULT_GW|
s|@MULTUS_AMF_N2@|$MULTUS_AMF_N2|
s|@IP_AMF_N2@|$IP_AMF_N2|
s|@NETMASK_AMF_N2@|$NETMASK_AMF_N2|
s|@MAC_AMF_N2@|$(gener-mac)|
s|@GW_AMF_N2@|$GW_AMF_N2|
s|@ROUTES_AMF_N2@|$ROUTES_AMF_N2|
s|@IF_NAME_AMF_N2@|$IF_NAME_AMF_N2|
s|@NODE_AMF@|"$NODE_AMF_UPF"|
s|@ENABLED_UPF@|$ENABLED_UPF|
s|@MULTUS_UPF_N3@|$MULTUS_UPF_N3|
s|@IP_UPF_N3@|$IP_UPF_N3|
s|@NETMASK_UPF_N3@|$NETMASK_UPF_N3|
s|@MAC_UPF_N3@|$(gener-mac)|
s|@GW_UPF_N3@|$GW_UPF_N3|
s|@ROUTES_UPF_N3@|$ROUTES_UPF_N3|
s|@IF_NAME_UPF_N3@|$IF_NAME_UPF_N3|
s|@MULTUS_UPF_N4@|$MULTUS_UPF_N4|
s|@IP_UPF_N4@|$IP_UPF_N4|
s|@NETMASK_UPF_N4@|$NETMASK_UPF_N4|
s|@MAC_UPF_N4@|$(gener-mac)|
s|@GW_UPF_N4@|$GW_UPF_N4|
s|@ROUTES_UPF_N4@|$ROUTES_UPF_N4|
s|@IF_NAME_UPF_N4@|$IF_NAME_UPF_N4|
s|@MULTUS_UPF_N6@|$MULTUS_UPF_N6|
s|@IP_UPF_N6@|$IP_UPF_N6|
s|@NETMASK_UPF_N6@|$NETMASK_UPF_N6|
s|@MAC_UPF_N6@|$(gener-mac)|
s|@GW_UPF_N6@|$GW_UPF_N6|
s|@ROUTES_UPF_N6@|$ROUTES_UPF_N6|
s|@IF_NAME_UPF_N6@|$IF_NAME_UPF_N6|
s|@NODE_UPF@|"$NODE_AMF_UPF"|
s|@ENABLED_TS@|$ENABLED_TS|
s|@MULTUS_TS@|$MULTUS_TS|
s|@IP_TS@|$IP_TS|
s|@NETMASK_TS@|$NETMASK_TS|
s|@MAC_TS@|$(gener-mac)|
s|@GW_TS@|$GW_TS|
s|@IF_NAME_TS@|$IF_NAME_TS|
s|@UPF_HOST@|"$UPF_HOST"|
s|@NODE_TS@|"$NODE_TS"|
s|@ENABLED_SMF@|$ENABLED_SMF|
s|@MULTUS_SMF_N4@|$MULTUS_SMF_N4|
s|@IP_SMF_N4@|$IP_SMF_N4|
s|@NETMASK_SMF_N4@|$NETMASK_SMF_N4|
s|@MAC_SMF_N4@|$(gener-mac)|
s|@GW_SMF_N4@|$GW_SMF_N4|
s|@ROUTES_SMF_N4@|$ROUTES_SMF_N4|
s|@IF_NAME_SMF_N4@|$IF_NAME_SMF_N4|
s|@NODE_SMF@||
EOF
    cp "$OAI5G_@MODE@"/values.yaml "$TMP"/@mode@_values.yaml-orig
    echo "(Over)writing $OAI5G_@MODE@/values.yaml"
    sed -f "$TMP"/@mode@-values.sed < "$TMP"/@mode@_values.yaml-orig > "$OAI5G_@MODE@"/values.yaml
    diff "$TMP"/@mode@_values.yaml-orig "$OAI5G_@MODE@"/values.yaml

    echo "Configuring chart $OAI5G_@MODE@/config.yaml for R2lab"
    cat > "$TMP"/@mode@-config.sed <<EOF
s|@NFS_AMF_HOST@|$NFS_AMF_HOST|
s|@NFS_SMF_HOST@|$NFS_SMF_HOST|
s|@NFS_UPF_HOST@|$NFS_UPF_HOST|
s|@NFS_UDM_HOST@|$NFS_UDM_HOST|
s|@NFS_UDR_HOST@|$NFS_UDR_HOST|
s|@NFS_AUSF_HOST@|$NFS_AUSF_HOST|
s|@NFS_NRF_HOST@|$NFS_NRF_HOST|
s|@IF_SBI@|$IF_SBI|
s|@IF_N2@|$IF_N2|
s|@IF_N3@|$IF_N3|
s|@IF_N4@|$IF_N4|
s|@IF_N6@|$IF_N6|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@TAC@|0x0001|
s|@ENABLE_SNAT@|$ENABLE_SNAT|
s|@DNN0@|$DNN0|
s|@DNN0_PDU_TYPE@|$DNN0_PDU_TYPE|
s|@DNN1@|$DNN1|
s|@DNN1_PDU_TYPE@|$DNN1_PDU_TYPE|
s|@SLICE1_SST@|$SLICE1_SST|
s|@SLICE1_SD@|$SLICE1_SD|
s|@SLICE1_5QI@|$SLICE1_5QI|
s|@SLICE1_UPLINK@|$SLICE1_UPLINK|
s|@SLICE1_DOWNLINK@|$SLICE1_DOWNLINK|
s|@SLICE2_SST@|$SLICE2_SST|
s|@SLICE2_SD@|$SLICE2_SD|
s|@SLICE2_5QI@|$SLICE2_5QI|
s|@SLICE2_UPLINK@|$SLICE2_UPLINK|
s|@SLICE2_DOWNLINK@|$SLICE2_DOWNLINK|
s|@IP_DNS1@|$IP_DNS1|
s|@IP_DNS2@|$IP_DNS2|
EOF
    cp "$OAI5G_@MODE@"/config.yaml "$TMP"/@mode@_config.yaml-orig
    echo "(Over)writing $OAI5G_@MODE@/config.yaml"
    sed -f "$TMP"/@mode@-config.sed < "$TMP"/@mode@_config.yaml-orig > "$OAI5G_@MODE@"/config.yaml
    # if SD NSSAI field is set to "NULL", erase the sd line
    awk '!/EMPTY/' "$OAI5G_@MODE@"/config.yaml > /tmp/temp && mv /tmp/temp "$OAI5G_@MODE@"/config.yaml
    diff "$TMP"/@mode@_config.yaml-orig "$OAI5G_@MODE@"/config.yaml
    cd "$OAI5G_@MODE@"
    echo "helm dependency update"
    helm dependency update
}

#################################################################################

configure-mysql() {

    DIR_ORIG_CHART="$OAI5G_CORE/mysql/initialization"
    DIR_PATCHED_CHART="$PREFIX_DEMO/oai5g-rru/patch-mysql"

    echo "configure-mysql: mysql database already patched by configure-demo-oai.sh script, just copy it"
    echo "cp $DIR_PATCHED_CHART/oai_db-basic.sql $DIR_ORIG_CHART/"
    cp $DIR_PATCHED_CHART/oai_db-basic.sql $DIR_ORIG_CHART/
    # if SD NSSAI field is set to "NULL", replace it by "FFFFFF" in the mysql database
    sed -i 's/EMPTY/FFFFFF/g' $DIR_ORIG_CHART/oai_db-basic.sql
}

#################################################################################



load_rru_env() {
    local file="$PREFIX_DEMO/rru/$1.env"
    [[ -f "$file" ]] || return 1
    set -a
    source "$file"
    set +a
}


apply-gnb-values-yq() {

    VALUES_FILE="$1"
    YQ_OVERLAY_FILE="$2"

    [ -f "$VALUES_FILE" ] || {
        echo "ERROR: values file not found: $VALUES_FILE"
        exit 1
    }

    [ -f "$YQ_OVERLAY_FILE" ] || {
        echo "ERROR: yq overlay file not found: $YQ_OVERLAY_FILE"
        exit 1
    }

    echo "Applying yq overlays from $YQ_OVERLAY_FILE to $VALUES_FILE"

    yq eval -i "$(cat "$YQ_OVERLAY_FILE")" "$VALUES_FILE"

    # Update PLMN and NSSAI
    yq eval -i '
.config.plmn_list[0].mcc = strenv(MCC) |
.config.plmn_list[0].mnc = strenv(MNC) |
.config.plmn_list[0].snssaiList =
[
  {
    "sst": strenv(SLICE1_SST),
    "sd": "0x" + (
      strenv(SLICE1_SD)
      | select(. != "" and . != "EMPTY")
      // "ffffff"
    )
  },
  {
    "sst": strenv(SLICE2_SST),
    "sd": "0x" + (
      strenv(SLICE2_SD)
      | select(. != "" and . != "EMPTY")
      // "ffffff"
    )
  }
]
' "$VALUES_FILE"
    
    # Validate new values.yaml configuration
    yq eval '.' "$VALUES_FILE" >/dev/null || {
        echo "ERROR: generated YAML is invalid: $VALUES_FILE"
        exit 1
    }
    echo "OK: $VALUES_FILE updated successfully"
}


configure-gnb() {
    echo "configure-gnb: gNB on node $NODE_GNB with RRU $RRU and logs is $LOGS"

    DIR_CHARTS="$PREFIX_DEMO/charts"

    
    # First load RU specific parameters
    load_rru_env "$RRU" || {
	echo "Unknown RRU: $RRU"
	exit 1
    }

    declare -A NF_IFS
    declare -A NF_IFS_START
    declare -A NF_IFS_END

    NF_IFS[oai-gnb]="
- name: \"n2\"
  enabled: $MULTUS_GNB_N2
  hostInterface: \"$IF_NAME_GNB_N2\"
  ipAdd: \"$IP_GNB_N2\"
  netmask: \"$NETMASK_GNB_N2\"
  defaultRoute: \"$GW_GNB_N2\"
  routes: \"$ROUTES_GNB_N2\"
  type: macvlan
  mode: \"bridge\"
- name: \"n3\"
  enabled: $MULTUS_GNB_N3
  hostInterface: \"$IF_NAME_GNB_N3\"
  ipAdd: \"$IP_GNB_N3\"
  netmask: \"$NETMASK_GNB_N3\"
  defaultRoute: \"$GW_GNB_N3\"
  routes: \"$ROUTES_GNB_N3\"
  type: macvlan
  mode: \"bridge\"
- name: \"e2\"
  enabled: $MULTUS_GNB_E2
  hostInterface: \"$IF_NAME_GNB_E2\"
  ipAdd: \"$IP_GNB_E2\"
  netmask: \"$NETMASK_GNB_E2\"
  type: macvlan
  mode: \"bridge\"
- name: \"ru\"
  enabled: $MULTUS_GNB_RU
  hostInterface: \"$IF_NAME_GNB_RU\"
  ipAdd: \"$IP_GNB_RU\"
  netmask: \"$NETMASK_GNB_RU\"
  gateway: \"$GW_GNB_RU\"
  mtu: \"$MTU_GNB_RU\"
  type: macvlan
  mode: \"bridge\"
  vlan: ""
"
    NF_IFS_END[oai-du]="
- name: \"e2\"
  enabled: $MULTUS_GNB_E2
  hostInterface: \"$IF_NAME_GNB_E2\"
  ipAdd: \"$IP_GNB_E2\"
  netmask: \"$NETMASK_GNB_E2\"
  type: macvlan
  mode: \"bridge\"
- name: \"ru\"
  enabled: $MULTUS_GNB_RU
  hostInterface: \"$IF_NAME_GNB_RU\"
  ipAdd: \"$IP_GNB_RU\"
  netmask: \"$NETMASK_GNB_RU\"
  gateway: \"$GW_GNB_RU\"
  mtu: \"$MTU_GNB_RU\"
  type: macvlan
  mode: \"bridge\"
  vlan: ""
"
    if [[ "$GNB_MODE" == 'cucpup' ]]; then
	NF_IFS_START[oai-du]="
- name: \"f1c\"
  enabled: $MULTUS_DU_F1C
  hostInterface: \"$IF_NAME_DU_F1C\"
  ipAdd: \"$IP_DU_F1C\"
  netmask: \"$NETMASK_DU_F1C\"
  defaultRoute: \"$GW_DU_F1C\"
  routes: \"$ROUTES_DU_F1C\"
  type: macvlan
  mode: \"bridge\"
- name: \"f1u\"
  enabled: $MULTUS_DU_F1U
  hostInterface: \"$IF_NAME_DU_F1U\"
  ipAdd: \"$IP_DU_F1U\"
  netmask: \"$NETMASK_DU_F1U\"
  defaultRoute: \"$GW_DU_F1U\"
  routes: \"$ROUTES_DU_F1U\"
  type: macvlan
  mode: \"bridge\"
"
    else
	NF_IFS_START[oai-du]="
- name: \"f1\"
  enabled: $MULTUS_DU_F1
  hostInterface: \"$IF_NAME_DU_F1\"
  ipAdd: \"$IP_DU_F1\"
  netmask: \"$NETMASK_DU_F1\"
  defaultRoute: \"$GW_DU_F1\"
  routes: \"$ROUTES_DU_F1\"
  type: macvlan
  mode: \"bridge\"
"
    fi
    NF_IFS[oai-du]="${NF_IFS_START[oai-du]}${NF_IFS_END[oai-du]}"
    
    NF_IFS[oai-gnb-fhi-72]="
- name: \"n2\"
  enabled: $MULTUS_GNB_N2
  hostInterface: \"$IF_NAME_GNB_N2\"
  ipAdd: \"$IP_GNB_N2\"
  netmask: \"$NETMASK_GNB_N2\"
  defaultRoute: \"$GW_GNB_N2\"
  routes: \"$ROUTES_GNB_N2\"
  type: macvlan
  mode: \"bridge\"
- name: \"n3\"
  enabled: $MULTUS_GNB_N3
  hostInterface: \"$IF_NAME_GNB_N3\"
  ipAdd: \"$IP_GNB_N3\"
  netmask: \"$NETMASK_GNB_N3\"
  defaultRoute: \"$GW_GNB_N3\"
  routes: \"$ROUTES_GNB_N3\"
  type: macvlan
  mode: \"bridge\"
- name: \"e2\"
  enabled: $MULTUS_GNB_E2
  hostInterface: \"$IF_NAME_GNB_E2\"
  ipAdd: \"$IP_GNB_E2\"
  netmask: \"$NETMASK_GNB_E2\"
  type: macvlan
  mode: \"bridge\"
- name: \"uplane1\"
  enabled: true
  mac: \"$MAC_UPLANE1\"
  type: sriov
  sriovNetworkNamespace: \"sriov-network-operator\"
  sriovResourceName: \"ruvfiou\"
  vlan: \"$VLAN_RU\"
- name: \"cplane1\"
  enabled: true
  mac: \"$MAC_CPLANE1\"
  type: sriov
  sriovNetworkNamespace: \"sriov-network-operator\"
  sriovResourceName: \"ruvfioc\"
  vlan: \"$VLAN_RU\"
"

    NF_IFS_END[oai-du-fhi-72]="
- name: \"e2\"
  enabled: $MULTUS_GNB_E2
  hostInterface: \"$IF_NAME_GNB_E2\"
  ipAdd: \"$IP_GNB_E2\"
  netmask: \"$NETMASK_GNB_E2\"
  type: macvlan
  mode: \"bridge\"
- name: \"uplane1\"
  enabled: true
  mac: \"$MAC_UPLANE1\"
  type: sriov
  sriovNetworkNamespace: \"sriov-network-operator\"
  sriovResourceName: \"ruvfiou\"
  vlan: \"$VLAN_RU\"
- name: \"cplane1\"
  enabled: true
  mac: \"$MAC_CPLANE1\"
  type: sriov
  sriovNetworkNamespace: \"sriov-network-operator\"
  sriovResourceName: \"ruvfioc\"
  vlan: \"$VLAN_RU\"
"
    if [[ "$GNB_MODE" == 'cucpup' ]]; then
	NF_IFS_START[oai-du-fhi-72]="
- name: \"f1c\"
  enabled: $MULTUS_GNB_F1C
  hostInterface: \"$IF_NAME_GNB_F1C\"
  ipAdd: \"$IP_GNB_F1C\"
  netmask: \"$NETMASK_GNB_F1C\"
  defaultRoute: \"$GW_GNB_F1C\"
  routes: \"$ROUTES_GNB_F1C\"
  type: macvlan
  mode: \"bridge\"
- name: \"f1u\"
  enabled: $MULTUS_GNB_F1U
  hostInterface: \"$IF_NAME_GNB_F1U\"
  ipAdd: \"$IP_GNB_F1U\"
  netmask: \"$NETMASK_GNB_F1U\"
  defaultRoute: \"$GW_GNB_F1U\"
  routes: \"$ROUTES_GNB_F1U\"
  type: macvlan
  mode: \"bridge\"
"
    else
	NF_IFS_START[oai-du-fhi-72]="
- name: \"f1\"
  enabled: $MULTUS_GNB_F1
  hostInterface: \"$IF_NAME_GNB_F1\"
  ipAdd: \"$IP_GNB_F1\"
  netmask: \"$NETMASK_GNB_F1\"
  defaultRoute: \"$GW_GNB_F1\"
  routes: \"$ROUTES_GNB_F1\"
  type: macvlan
  mode: \"bridge\"
"
    fi
    NF_IFS[oai-du-fhi-72]="${NF_IFS_START[oai-du-fhi-72]}${NF_IFS_END[oai-du-fhi-72]}"

        NF_IFS[oai-cu]="
- name: \"n2\"
  enabled: $MULTUS_CU_N2
  hostInterface: \"$IF_NAME_CU_N2\"
  ipAdd: \"$IP_CU_N2\"
  netmask: \"$NETMASK_CU_N2\"
  defaultRoute: \"$GW_CU_N2\"
  routes: \"$ROUTES_CU_N2\"
  type: macvlan
  mode: \"bridge\"
- name: \"f1\"
  enabled: $MULTUS_CU_F1
  hostInterface: \"$IF_NAME_CU_F1\"
  ipAdd: \"$IP_CU_F1\"
  netmask: \"$NETMASK_CU_F1\"
  defaultRoute: \"$GW_CU_F1\"
  routes: \"$ROUTES_CU_F1\"
  type: macvlan
  mode: \"bridge\"
- name: \"n3\"
  enabled: $MULTUS_CU_N3
  hostInterface: \"$IF_NAME_CU_N3\"
  ipAdd: \"$IP_CU_N3\"
  netmask: \"$NETMASK_CU_N3\"
  defaultRoute: \"$GW_CU_N3\"
  routes: \"$ROUTES_CU_N3\"
  type: macvlan
  mode: \"bridge\"
- name: \"e2\"
  enabled: $MULTUS_CU_E2
  hostInterface: \"$IF_NAME_CU_E2\"
  ipAdd: \"$IP_CU_E2\"
  netmask: \"$NETMASK_CU_E2\"
  type: macvlan
  mode: \"bridge\"
"
	NF_IFS[oai-cu-cp]="
- name: \"n2\"
  enabled: $MULTUS_CUCP_N2
  hostInterface: \"$IF_NAME_CUCP_N2\"
  ipAdd: \"$IP_CUCP_N2\"
  netmask: \"$NETMASK_CUCP_N2\"
  defaultRoute: \"$GW_CUCP_N2\"
  routes: \"$ROUTES_CUCP_N2\"
  type: macvlan
  mode: \"bridge\"
- name: \"f1c\"
  enabled: $MULTUS_CUCP_F1C
  hostInterface: \"$IF_NAME_CUCP_F1C\"
  ipAdd: \"$IP_CUCP_F1C\"
  netmask: \"$NETMASK_CUCP_F1C\"
  gateway: \"$GW_CUCP_F1C\"
  routes: \"$ROUTES_CUCP_F1C\"
  type: macvlan
  mode: \"bridge\"
- name: \"e1\"
  enabled: $MULTUS_CUCP_E1
  hostInterface: \"$IF_NAME_CUCP_E1\"
  ipAdd: \"$IP_CUCP_E1\"
  netmask: \"$NETMASK_CUCP_E1\"
  gateway: \"$GW_CUCP_E1\"
  routes: \"$ROUTES_CUCP_E1\"
  type: macvlan
  mode: \"bridge\"
- name: \"e2\"
  enabled: $MULTUS_CUCP_E2
  hostInterface: \"$IF_NAME_CUCP_E2\"
  ipAdd: \"$IP_CUCP_E2\"
  netmask: \"$NETMASK_CUCP_E2\"
  type: macvlan
  mode: \"bridge\"
"
	NF_IFS[oai-cu-up]="
- name: \"n3\"
  enabled: $MULTUS_CUUP_N3
  hostInterface: \"$IF_NAME_CUUP_N3\"
  ipAdd: \"$IP_CUUP_N3\"
  netmask: \"$NETMASK_CUUP_N3\"
  defaultRoute: \"$GW_CUUP_N3\"
  routes: \"$ROUTES_CUUP_N3\"
  type: macvlan
  mode: \"bridge\"
- name: \"f1u\"
  enabled: $MULTUS_CUUP_F1U
  hostInterface: \"$IF_NAME_CUUP_F1U\"
  ipAdd: \"$IP_CUUP_F1U\"
  netmask: \"$NETMASK_CUUP_F1U\"
  gateway: \"$GW_CUUP_F1U\"
  routes: \"$ROUTES_CUUP_F1U\"
  type: macvlan
  mode: \"bridge\"
- name: \"e1\"
  enabled: $MULTUS_CUUP_E1
  hostInterface: \"$IF_NAME_CUUP_E1\"
  ipAdd: \"$IP_CUUP_E1\"
  netmask: \"$NETMASK_CUUP_E1\"
  gateway: \"$GW_CUUP_E1\"
  routes: \"$ROUTES_CUUP_E1\"
  type: macvlan
  mode: \"bridge\"
- name: \"e2\"
  enabled: $MULTUS_CUUP_E2
  hostInterface: \"$IF_NAME_CUUP_E2\"
  ipAdd: \"$IP_CUUP_E2\"
  netmask: \"$NETMASK_CUUP_E2\"
  type: macvlan
  mode: \"bridge\"
"
  
    for nf in oai-gnb oai-gnb-fhi-72 oai-du oai-du-fhi-72 oai-cu oai-cu-cp oai-cu-up; do
	VALUES="${OAI5G_RAN}/${nf}/values.yaml"
	    
	if [[ ! -f "$VALUES" ]]; then
	    echo "Skipping $nf: file not found"
	    continue
	fi	
	cp "$VALUES" "${OAI5G_RAN}/${nf}/values.yaml.orig"
	    
	# First remove multus interfaces
	yq eval -i 'del(.multus.interfaces)' "$VALUES"
	
	# Inject interfaces
	export YQ_IFS="${NF_IFS[$nf]}"

	if [[ -z "$YQ_IFS" ]]; then
	    echo "ERROR: NF_IFS[$nf] is empty"
	    continue
	fi

	yq eval -i '
           .multus.enabled = true |
	   .multus.interfaces = (strenv(YQ_IFS) | from_yaml)
        ' "$VALUES"

	# Update remaining parameters
	apply-gnb-values-yq "${VALUES}" "${PREFIX_DEMO}/oai5g-rru/charts/values/${nf}.yq"
	diff -u <(yq eval -P '.' ${OAI5G_RAN}/${nf}/values.yaml.orig) <(yq eval -P '.' ${VALUES})
    done

    # Update config.yaml charts
    if [[ $GNB_MODE = 'monolithic' ]]; then
	gnb_type="gnb"
	if [[ "$RRU_TYPE" == "benetel" ]]; then
	    nf="oai-gnb-fhi-72"
	else
	    nf="oai-gnb"
	fi
    else
	gnb_type="du"
	if [[ "$RRU_TYPE" == "benetel" ]]; then
	    nf="oai-du-fhi-72"
	else
	    nf="oai-du"
	fi
    fi
    CONFIG_RRU="$PREFIX_DEMO/rru/${gnb_type}-config-${RRU_TYPE}.yaml"
    CONFIG="${OAI5G_RAN}/${nf}/config.yaml"
    cp "$CONFIG" "${OAI5G_RAN}/${nf}/config.yaml.orig"
    cp "$CONFIG_RRU" "$CONFIG"
    diff -u <(yq eval -P '.' ${OAI5G_RAN}/${nf}/config.yaml.orig) <(yq eval -P '.' ${CONFIG})

    # Fix deployment charts in the case of AW2S RUs as Eurecom no more support AW2S...
    if [[ "$RRU_TYPE" == "aw2s" ]]; then
	for nf in oai-gnb oai-du; do
	    cp "$PREFIX_DEMO/rru/${nf}-deployment-aw2s.yaml" "${OAI5G_RAN}/${nf}/templates/deployment.yaml"
	done
	for nf in oai-cu oai-cu-cp oai-cu-up; do
	    DEPLOYMENT="${OAI5G_RAN}/${nf}/templates/deployment.yaml"
	    sed -i 's|/opt/oai-gnb/etc|/opt/oai-gnb-aw2s/etc|' "$DEPLOYMENT"
	done
    fi
    
}



#################################################################################

configure-nr-ue() {

    # will NOT generate PCAP file to avoid wasting all memory resources
    # However, a tcpdump container created e.g., to run iperf client"
    DIR="$OAI5G_RAN/oai-nr-ue"
    ORIG_CHART="${DIR}/values.yaml"
    SED_FILE="${TMP}/oai-nr-ue-values.sed"
    echo "configure-nr-ue: $ORIG_CHART configuration"
    ADD_OPTIONS_NRUE="$OPTIONS_NRUE"
    cat > "$SED_FILE" <<EOF
s|@NRUE_REPO@|$NRUE_REPO|
s|@NRUE_TAG@|$NRUE_TAG|
s|@MULTUS_NRUE@|$MULTUS_NRUE|
s|@IP_NRUE@|$IP_NRUE|
s|@NETMASK_NRUE@|$NETMASK_NRUE|
s|@MAC_NRUE@|$(gener-mac)|
s|@DEFAULT_GW_NRUE@|$DEFAULT_GW_NRUE|
s|@IF_NAME_NRUE@|$IF_NAME_NRUE|
s|@RFSIM_IMSI@|$RFSIM_IMSI|
s|@FULL_KEY@|$FULL_KEY|
s|@OPC@|$OPC|
s|@DNN@|$DNN0|
s|@SST@|$SLICE1_SST|
s|@SD@|0x$SLICE1_SD|
s|@NRUE_USRP@|$NRUE_USRP|
s|@ADD_OPTIONS_NRUE@|$ADD_OPTIONS_NRUE|
s|@START_TCPDUMP@|false|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@QOS_NRUE_DEF@|false|
s|@SHAREDVOLUME@|false|
s|@NODE_NRUE@||
EOF
    cp "$ORIG_CHART" "$TMP"/oai-nr-ue_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < "$TMP"/oai-nr-ue_values.yaml-orig > "$ORIG_CHART"
    # if SD NSSAI field is set to "NULL", replace it by "16777215"
    sed -i 's/0xEMPTY/16777215/g' "$ORIG_CHART"
    diff "$TMP"/oai-nr-ue_values.yaml-orig "$ORIG_CHART"
}

#################################################################################

configure-nr-ue2() {

    # will NOT generate PCAP file to avoid wasting all memory resources
    # However, a tcpdump container created e.g., to run iperf client"
    DIR="${OAI5G_RAN}/oai-nr-ue2"
    ORIG_CHART="${DIR}/values.yaml"
    SED_FILE="${TMP}/oai-nr-ue2-values.sed"
    echo "configure-nr-ue2: $ORIG_CHART configuration"
    ADD_OPTIONS_NRUE="$OPTIONS_NRUE"
    cat > "$SED_FILE" <<EOF
s|@NRUE_REPO@|$NRUE_REPO|
s|@NRUE_TAG@|$NRUE_TAG|
s|@MULTUS_NRUE2@|$MULTUS_NRUE|
s|@IP_NRUE2@|$IP_NRUE2|
s|@NETMASK_NRUE2@|$NETMASK_NRUE|
s|@MAC_NRUE2@|$(gener-mac)|
s|@DEFAULT_GW_NRUE2@|$DEFAULT_GW_NRUE|
s|@IF_NAME_NRUE2@|$IF_NAME_NRUE|
s|@RFSIM_IMSI_UE2@|$RFSIM_IMSI_UE2|
s|@FULL_KEY_UE2@|$FULL_KEY|
s|@OPC_UE2@|$OPC|
s|@DNN_UE2@|$DNN1|
s|@SST_UE2@|$SLICE2_SST|
s|@SD_UE2@|0x$SLICE2_SD|
s|@NRUE2_USRP@|$NRUE_USRP|
s|@ADD_OPTIONS_NRUE2@|$ADD_OPTIONS_NRUE|
s|@START_TCPDUMP@|false|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@QOS_NRUE2_DEF@|false|
s|@SHAREDVOLUME@|false|
s|@NODE_NRUE2@||
EOF
    cp "$ORIG_CHART" "$TMP"/oai-nr-ue2_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < "$TMP"/oai-nr-ue2_values.yaml-orig > "$ORIG_CHART"
    # if SD NSSAI field is set to "NULL", replace it by "16777215"
    sed -i 's/0xEMPTY/16777215/g' "$ORIG_CHART"
    diff "$TMP"/oai-nr-ue2_values.yaml-orig "$ORIG_CHART"
}

#################################################################################

configure-nr-ue3() {

    # will NOT generate PCAP file to avoid wasting all memory resources
    # However, a tcpdump container created e.g., to run iperf client"
    DIR="${OAI5G_RAN}/oai-nr-ue3"
    ORIG_CHART="${DIR}/values.yaml"
    SED_FILE="${TMP}/oai-nr-ue3-values.sed"
    echo "configure-nr-ue3: $ORIG_CHART configuration"
    ADD_OPTIONS_NRUE="$OPTIONS_NRUE"
    cat > "$SED_FILE" <<EOF
s|@NRUE_REPO@|$NRUE_REPO|
s|@NRUE_TAG@|$NRUE_TAG|
s|@MULTUS_NRUE3@|$MULTUS_NRUE|
s|@IP_NRUE3@|$IP_NRUE3|
s|@NETMASK_NRUE3@|$NETMASK_NRUE|
s|@MAC_NRUE3@|$(gener-mac)|
s|@DEFAULT_GW_NRUE3@|$DEFAULT_GW_NRUE|
s|@IF_NAME_NRUE3@|$IF_NAME_NRUE|
s|@RFSIM_IMSI_UE3@|$RFSIM_IMSI_UE3|
s|@FULL_KEY_UE3@|$FULL_KEY|
s|@OPC_UE3@|$OPC|
s|@DNN_UE3@|$DNN0|
s|@SST_UE3@|$SLICE1_SST|
s|@SD_UE3@|0x$SLICE1_SD|
s|@NRUE3_USRP@|$NRUE_USRP|
s|@ADD_OPTIONS_NRUE3@|$ADD_OPTIONS_NRUE|
s|@START_TCPDUMP@|false|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@QOS_NRUE3_DEF@|false|
s|@SHAREDVOLUME@|false|
s|@NODE_NRUE3@||
EOF
    cp "$ORIG_CHART" "$TMP"/oai-nr-ue3_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < "$TMP"/oai-nr-ue3_values.yaml-orig > "$ORIG_CHART"
    # if SD NSSAI field is set to "NULL", replace it by "16777215"
    sed -i 's/0xEMPTY/16777215/g' "$ORIG_CHART"
    diff "$TMP"/oai-nr-ue3_values.yaml-orig "$ORIG_CHART"
}

#################################################################################

configure-flexric() {

    DIR="$OAI5G_RAN/oai-flexric"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="$TMP/oai-flexric-values.sed"
    echo "configure-flexric: $ORIG_CHART configuration"
    cat > "$SED_FILE" <<EOF
s|@FLEXRIC_REPO@|$FLEXRIC_REPO|
s|@FLEXRIC_TAG@|$FLEXRIC_TAG|
s|@FLEXRIC_PULL_POLICY@|$FLEXRIC_PULL_POLICY|
EOF
    cp "$ORIG_CHART" "$TMP"/oai-flexric_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < "$TMP"/oai-flexric_values.yaml-orig > "$ORIG_CHART"
    # if SD NSSAI field is set to "NULL", replace it by "16777215"
    sed -i 's/0xEMPTY/16777215/g' "$ORIG_CHART"
    diff "$TMP"/oai-flexric_values.yaml-orig "$ORIG_CHART"
}


#################################################################################

configure-all() {
    echo "configure-all: Applying SophiaNode patches to OAI5G charts located on \"$PREFIX_DEMO/oai-cn5g-fed\""
    echo -e "\t with oai-upf running on \"$NODE_AMF_UPF\""
    echo -e "\t with oai-gnb running on \"$NODE_GNB\""
    echo -e "\t with generate-logs: \"$LOGS\""
    echo -e "\t with generate-pcap: \"$PCAP\""

    # Remove pulling limitations from docker-hub with anonymous account
    echo "Create $NS if not present and regcred secret"	     
    kubectl create namespace "$NS" || true
    kubectl -n "$NS" delete secret regcred || true
    kubectl -n "$NS" create secret docker-registry regcred \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username="@DEF_REGCRED_NAME@" \
        --docker-password="@DEF_REGCRED_PWD@" \
        --docker-email="@DEF_REGCRED_EMAIL@" || true

    # Ensure that helm spray plugin is installed
    configure-oai-5g-@mode@ 
    configure-mysql
    configure-gnb
    configure-flexric
    if [[ "$RRU" = "rfsim" ]]; then
	configure-nr-ue
    configure-nr-ue2
    configure-nr-ue3
    fi
}

#################################################################################


start-cn() {
    echo "Running start-cn() with namespace=$NS, NODE_AMF_UPF=$NODE_AMF_UPF"
    echo "cd $OAI5G_@MODE@"
    cd "$OAI5G_@MODE@" || { echo "Error: Failed to change directory"; exit 1; }

    echo "helm dependency update"
    if ! helm dependency update; then
        echo "Error: Failed to update helm dependencies"
        exit 1
    fi

    echo "helm --namespace=$NS install oai-5g-@mode@ ."
    if ! helm --create-namespace --namespace="$NS" install oai-5g-@mode@ . --wait --timeout=300s; then
        echo "Error: Failed to install helm chart"
        exit 1
    fi

    echo "Wait until all 5G Core pods are READY"
    if ! kubectl wait pod \
        --namespace="$NS" \
        --for=condition=Ready \
        --selector='app.kubernetes.io/instance=oai-5g-@mode@' \
        --timeout=300s; then
        echo "Error: 5G Core pods did not become ready within timeout"
        exit 1
    fi
    echo "✔ All 5G Core pods are READY"
}

################################################################################

start-flexric() {

    echo "Running start-flexric() on namespace: $NS, NODE_GNB=$NODE_GNB"
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    echo "helm -n $NS install oai-flexric oai-flexric/" 
    helm -n $NS install oai-flexric oai-flexric/

    echo "Wait until oai-flexric pod is READY"
    kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-flexric
}

#################################################################################


start-gnb() {
    echo "Running gNB on $NS namespace with GNB_MODE=$GNB_MODE, NODE_GNB=$NODE_GNB and rru=$RRU"

    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    if [[ $GNB_MODE = 'monolithic' ]]; then
	echo "helm -n $NS install oai-gnb oai-gnb/"
	helm -n $NS install oai-gnb oai-gnb/
	echo "Wait until the gNB pod is READY"
	kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-gnb
    elif [[ $GNB_MODE = 'cudu' ]]; then
	echo "helm -n $NS install oai-cu oai-cu/"
	helm -n $NS install oai-cu oai-cu/

	echo "sleep 5s"; sleep 5
	echo "kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu"
	kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu
	echo "helm install -n $NS oai-du oai-du/"
	helm install -n $NS oai-du oai-du/
    else
	# $GNB_MODE = 'cucpup'
	echo "helm -n $NS install oai-cu-cp oai-cu-cp/"
	helm -n $NS install oai-cu-cp oai-cu-cp/
	echo "sleep 10s"; sleep 10
	echo "kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu-cp"
	kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu-cp
	echo "helm -n $NS install oai-cu-up oai-cu-up/"
	helm -n $NS install oai-cu-up oai-cu-up/
	echo "sleep 5s"; sleep 5
	echo "kubectl -n $NS wait pod --for=condition=Ready  -l app.kubernetes.io/instance=oai-cu-up"
	kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu-up
	echo "helm install -n $NS oai-du oai-du/"
	helm install -n $NS oai-du oai-du/
    fi
}

#################################################################################

start-nr-ue() {

    echo "Running start-nr-ue() on namespace: $NS, NODE_GNB=$NODE_GNB"
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    if [[ $MULTUS_NRUE == "true" ]]; then
       GNB_IP="$IP_GNB_N3"
    else
	echo "retrieve dynamically gNB/DU IP"
	if [[ $GNB_MODE == 'monolithic' ]]; then
	    GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
	else
	    GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	fi
    fi
    echo "sed set rfSimServer to $GNB_IP in ${OAI5G_RAN}/oai-nr-ue/values.yaml"
    sed -i "s/rfSimServer:.*/rfSimServer: \"$GNB_IP\"/" ${OAI5G_RAN}/oai-nr-ue/values.yaml

    echo "helm -n $NS install oai-nr-ue oai-nr-ue/" 
    helm -n $NS install oai-nr-ue oai-nr-ue/

    echo "Wait until oai-nr-ue pod is READY"
    kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-nr-ue
}

################################################################################

start-nr-ue2() {

    echo "Running start-nr-ue2() on namespace: $NS, NODE_GNB=$NODE_GNB"
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    if [[ $MULTUS_NRUE == "true" ]]; then
       GNB_IP="$IP_GNB_N3"
    else
	echo "retrieve dynamically gNB/DU IP"
	if [[ $GNB_MODE == 'monolithic' ]]; then
	    GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
	else
	    GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	fi
    fi
    echo "sed set rfSimServer to $GNB_IP in ${OAI5G_RAN}/oai-nr-ue2/values.yaml"
    sed -i "s/rfSimServer:.*/rfSimServer: \"$GNB_IP\"/" ${OAI5G_RAN}/oai-nr-ue2/values.yaml

    echo "helm -n $NS install oai-nr-ue2 oai-nr-ue2/" 
    helm -n $NS install oai-nr-ue2 oai-nr-ue2/

    echo "Wait until oai-nr-ue2 pod is READY"
    kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-nr-ue2
}

#################################################################################

start-nr-ue3() {

    echo "Running start-nr-ue3() on namespace: $NS, NODE_GNB=$NODE_GNB"
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    if [[ $MULTUS_NRUE == "true" ]]; then
       GNB_IP="$IP_GNB_N3"
    else
	echo "retrieve dynamically gNB/DU IP"
	if [[ $GNB_MODE == 'monolithic' ]]; then
	    GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
	else
	    GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	fi
    fi
    echo "sed set rfSimServer to $GNB_IP in ${OAI5G_RAN}/oai-nr-ue3/values.yaml"
    sed -i "s/rfSimServer:.*/rfSimServer: \"$GNB_IP\"/" ${OAI5G_RAN}/oai-nr-ue3/values.yaml

    echo "helm -n $NS install oai-nr-ue3 oai-nr-ue3/" 
    helm -n $NS install oai-nr-ue3 oai-nr-ue3/

    echo "Wait until oai-nr-ue3 pod is READY"
    kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-nr-ue3
}

#################################################################################

# Add logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# Update logging calls
start() {
    log "INFO" "Starting all oai5g pods on namespace=$NS"

    if [[ $LOGS = "true" ]]; then
        log "INFO" "Creating k8s persistence volume for generation of RAN logs files"
        cat << \EOF >> "$TMP"/oai5g-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: oai5g-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteMany
  hostPath:
    path: /var/oai5g-volume
EOF
	kubectl apply -f "$TMP"/oai5g-pv.yaml

	echo "start: Create a k8s persistence volume for generation of CN logs files"
	cat << \EOF >> "$TMP"/cn5g-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cn5g-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteMany
  hostPath:
    path: /var/cn5g-volume
EOF
	kubectl apply -f "$TMP"/cn5g-pv.yaml

	
	echo "start: Create a k8s persistent volume claim for RAN logs files"
    cat << \EOF >> "$TMP"/oai5g-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oai5g-pvc
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
  - ReadWriteMany
  storageClassName: ""
  volumeName: oai5g-pv
EOF
    echo "kubectl -n $NS apply -f ${TMP}/oai5g-pvc.yaml"
    kubectl -n $NS apply -f "$TMP"/oai5g-pvc.yaml

	echo "start: Create a k8s persistent volume claim for CN logs files"
    cat << \EOF >> "$TMP"/cn5g-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cn5g-pvc
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
  - ReadWriteMany
  storageClassName: ""
  volumeName: cn5g-pv
EOF
    echo "kubectl -n $NS apply -f ${TMP}/cn5g-pvc.yaml"
    kubectl -n $NS apply -f "$TMP"/cn5g-pvc.yaml
    fi

    if [[ "$RUN_MODE" != "gnb-only" ]]; then
	start-cn 
    fi
    
    if [[ $FLEXRIC = "true" ]]; then
	start-flexric
    fi

    echo "sleep 20s before running RAN pods"; sleep 20
    start-gnb 

    if [[ "$RRU" == "rfsim" ]]; then
	echo "sleep 5s before starting nr-ue and nr-ue2"; sleep 5
	start-nr-ue
	start-nr-ue2
    fi

    echo "****************************************************************************"
    echo "When you finish, to clean-up the k8s cluster, please run demo-oai.py --clean"
}

#################################################################################

run-ping() {
    UE_POD_NAME=$(kubectl -n $NS get pods -l app.kubernetes.io/name=oai-nr-ue -o jsonpath="{.items[0].metadata.name}")
    echo "kubectl -n $NS exec -it $UE_POD_NAME -c nr-ue -- /bin/ping --I oaitun_ue1 c4 google.fr"
    kubectl -n $NS exec -it "$UE_POD_NAME" -c nr-ue -- /bin/ping -I oaitun_ue1 -c4 google.fr
}

#################################################################################

stop-cn(){
    echo "helm --namespace=$NS uninstall oai-5g-@mode@"
    helm --namespace=$NS uninstall oai-5g-@mode@ 
}

stop-flexric(){
    echo "helm -n $NS uninstall flexric"
    helm -n $NS uninstall oai-flexric
}

stop-gnb(){
    if [[ $GNB_MODE = 'monolithic' ]]; then
	echo "helm -n $NS uninstall oai-gnb"
	helm -n $NS uninstall oai-gnb
    else
	echo "helm -n $NS uninstall oai-du"
	helm -n $NS uninstall oai-du
	if [[ $GNB_MODE = 'cudu' ]]; then
	    echo "helm -n $NS uninstall oai-cu"
	    helm -n $NS uninstall oai-cu
	else
	    # $GNB_MODE = 'cucpup'
	    echo "helm -n $NS uninstall oai-cu-up"
	    helm -n $NS uninstall oai-cu-up
	    echo "helm -n $NS uninstall oai-cu-cp"
	    helm -n $NS uninstall oai-cu-cp
	fi
    fi
}


stop-nr-ue(){
    echo "helm -n $NS uninstall oai-nr-ue"
    helm -n $NS uninstall oai-nr-ue
}


stop-nr-ue2(){
    echo "helm -n $NS uninstall oai-nr-ue2"
    helm -n $NS uninstall oai-nr-ue2
}

stop-nr-ue3(){
    echo "helm -n $NS uninstall oai-nr-ue3"
    helm -n $NS uninstall oai-nr-ue3
}

stop() {
    echo "Running stop() on $NS namespace, logs=$LOGS"

    if [[ "$LOGS" = "true" ]]; then
	DATE=$(date +"%Y-%m-%dT%H.%M")
	dir_stats=${PREFIX_STATS-"$TMP/oai5g-stats"}-"$DATE"
	echo "First retrieve all pcap and logs files in $dir_stats and compressed it"
	mkdir -p "$dir_stats"
	echo "cleanup $dir_stats before including new logs/pcap files"
	cd "$dir_stats"; rm -f *.pcap *.tgz *.logs *stats* *.conf
	if [[ "$PCAP" = "true" ]]; then
	    get-all-pcap "$dir_stats"
	fi
	get-all-logs "$dir_stats"
	cd "$TMP"; dirname=$(basename "$dir_stats")
	echo tar cfz "$dirname".tgz "$dirname"
	tar cfz "$dirname".tgz "$dirname"
    fi

    res=$(helm -n $NS ls | wc -l)
    if test "$res" -gt 1; then
        echo "Remove all 5G OAI pods"
	if [[ "$RUN_MODE" != "gnb-only" ]]; then
	    stop-cn
	fi
	if [[ $FLEXRIC = "true" ]]; then
	    stop-flexric
	fi
	stop-gnb
	if [[ "$RRU" = "rfsim" ]]; then
	    stop-nr-ue
            stop-nr-ue2
	fi
    else
        echo "OAI5G demo is not running, there is no pod on namespace $NS !"
    fi

    echo "Wait until all $NS pods disappear"
    kubectl delete pods -n $NS --all --wait --cascade=foreground

    if [[ "$LOGS" = "true" ]]; then
	echo "Delete k8s persistence volume / claim for logs/pcap files"
	kubectl -n $NS delete pvc oai5g-pvc || true
	kubectl -n $NS delete pvc cn5g-pvc || true
	kubectl delete pv oai5g-pv || true
	kubectl delete pv cn5g-pv || true
    fi
}


#################################################################################
#################################################################################


get-all-logs() {
    prefix=$1; shift

    DATE=$(date +"%Y-%m-%dT%H.%M.%S")

    echo "get-all-logs: saving charts"
    tar -C "$PREFIX_DEMO"/oai-cn5g-fed -cf "$prefix"/charts.tar charts

    echo "get-all-logs: saving demo-oai.sh script"
    cp "$PREFIX_DEMO"/demo-oai.sh "$prefix"/

    if [[ -f "$PREFIX_DEMO"/prepare-demo-oai.sh ]]; then
        echo "get-all-logs: saving prepare-demo-oai.sh script"
    	cp "$PREFIX_DEMO"/prepare-demo-oai.sh "$prefix"/
    fi

    AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    AMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-amf $AMF_POD_NAME running with IP $AMF_eth0_IP"
    kubectl --namespace $NS -c amf logs "$AMF_POD_NAME" > "$prefix"/amf-"$DATE".logs

    AUSF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    AUSF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-ausf $AUSF_POD_NAME running with IP $AUSF_eth0_IP"
    kubectl --namespace $NS -c ausf logs "$AUSF_POD_NAME" > "$prefix"/ausf-"$DATE".logs

    NRF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    NRF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-nrf $NRF_POD_NAME running with IP $NRF_eth0_IP"
    kubectl --namespace $NS -c nrf logs "$NRF_POD_NAME" > "$prefix"/nrf-"$DATE".logs

    SMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    SMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-smf $SMF_POD_NAME running with IP $SMF_eth0_IP"
    kubectl --namespace $NS -c smf logs "$SMF_POD_NAME" > "$prefix"/smf-"$DATE".logs

    UPF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-upf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UPF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-upf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-upf $UPF_POD_NAME running with IP $UPF_eth0_IP"
    kubectl --namespace $NS -c upf logs "$UPF_POD_NAME" > "$prefix"/upf-"$DATE".logs

    UDM_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UDM_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-udm $UDM_POD_NAME running with IP $UDM_eth0_IP"
    kubectl --namespace $NS -c udm logs "$UDM_POD_NAME" > "$prefix"/udm-"$DATE".logs
    
    UDR_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UDR_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-udr $UDR_POD_NAME running with IP $UDR_eth0_IP"
    kubectl --namespace $NS -c udr logs "$UDR_POD_NAME" > "$prefix"/udr-"$DATE".logs

    if [[ $GNB_MODE = 'monolithic' ]]; then
	GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
	GNB_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-gnb $GNB_POD_NAME running with IP $GNB_eth0_IP"
	kubectl --namespace $NS -c gnb logs "$GNB_POD_NAME" > "$prefix"/gnb-"$DATE".logs
	echo "Retrieve gnb config from the pod"
	kubectl -c gnb cp $NS/"GNB_POD_NAME":/tmp/gnb.conf "$prefix"/gnb.conf || true
	echo "Retrieve nrL1_stats.log, nrMAC_stats.log and nrRRC_stats.log from gnb pod"
	kubectl -c gnb cp $NS/"$GNB_POD_NAME":nrL1_stats.log "$prefix"/nrL1_stats.log"$DATE" || true
	kubectl -c gnb cp $NS/"$GNB_POD_NAME":nrMAC_stats.log "$prefix"/nrMAC_stats.log"$DATE" || true
	kubectl -c gnb cp $NS/"$GNB_POD_NAME":nrRRC_stats.log "$prefix"/nrRRC_stats.log"$DATE" || true
    elif [[ $GNB_MODE = 'cudu' ]]; then
	CU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[0].metadata.name}")
	CU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-cu $CU_POD_NAME running with IP $CU_eth0_IP"
	kubectl --namespace $NS -c oai-cu logs "$CU_POD_NAME" > "$prefix"/cu-"$DATE".logs
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	kubectl -c gnbdu cp $NS/"$DU_POD_NAME":nrL1_stats.log "$prefix"/nrL1_stats.log"$DATE" || true
	kubectl -c gnbdu cp $NS/"$DU_POD_NAME":nrMAC_stats.log "$prefix"/nrMAC_stats.log"$DATE" || true
	kubectl -c oai-cu cp $NS/"$CU_POD_NAME":nrRRC_stats.log "$prefix"/nrRRC_stats.log"$DATE" || true
	DU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-du $DU_POD_NAME running with IP $DU_eth0_IP"
	kubectl --namespace $NS -c gnbdu logs "$DU_POD_NAME" > "$prefix"/du-"$DATE".logs
	echo "Retrieve cu/du configs from the pods"
	kubectl -c oai-cu cp $NS/"$CU_POD_NAME":/tmp/cu.conf "$prefix"/cu.conf || true
	kubectl -c gnbdu cp $NS/"$DU_POD_NAME":/tmp/du.conf "$prefix"/du.conf || true
    else
	# $GNB_MODE = 'cucpup'
	CUCP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[0].metadata.name}")
	CUCP_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oaicucp $CUCP_POD_NAME running with IP $CUCP_eth0_IP"
	kubectl --namespace $NS -c oaicucp logs "$CUCP_POD_NAME" > "$prefix"/cucp-"$DATE".logs
	CUUP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[0].metadata.name}")
	CUUP_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oaicuup $CUUP_POD_NAME running with IP $CUUP_eth0_IP"
	kubectl --namespace $NS -c oaicuup logs "$CUUP_POD_NAME" > "$prefix"/cuup-"$DATE".logs
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	kubectl -c gnbdu cp $NS/"$DU_POD_NAME":nrL1_stats.log "$prefix"/nrL1_stats.log"$DATE" || true
	kubectl -c gnbdu cp $NS/"$DU_POD_NAME":nrMAC_stats.log "$prefix"/nrMAC_stats.log"$DATE" || true
	kubectl -c oaicucp cp $NS/"$CUCP_POD_NAME":nrRRC_stats.log "$prefix"/nrRRC_stats.log"$DATE" || true
	DU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-du $DU_POD_NAME running with IP $DU_eth0_IP"
	kubectl --namespace $NS -c gnbdu logs "$DU_POD_NAME" > "$prefix"/du-"$DATE".logs
	echo "Retrieve cucp/cuup/du configs from the pods"
	kubectl -c oaicucp cp $NS/"$CUCP_POD_NAME":/tmp/cucp.conf "$prefix"/cucp.conf || true
	kubectl -c oaicuup cp $NS/"$CUUP_POD_NAME":/tmp/cuup.conf "$prefix"/cuup.conf || true
	kubectl -c gnbdu cp $NS/"$DU_POD_NAME":/tmp/du.conf "$prefix"/du.conf || true
    fi

    if [[ "$RRU" = "rfsim" ]]; then
	NRUE_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
	NRUE_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-nr-ue $NRUE_POD_NAME running with IP $NRUE_eth0_IP"
	kubectl --namespace $NS -c nr-ue logs "$NRUE_POD_NAME" > "$prefix"/nr-ue-"$DATE".logs
    fi

}

#################################################################################

get-cn-pcap(){
    prefix=$1; shift

    DATE=$(date +"%Y-%m-%dT%H.%M.%S")

    AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G CN pcap files from the AMF pod on ns $NS"
    echo "kubectl -c tcpdump -n $NS exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz -C tmp pcap"
    kubectl -c tcpdump -n $NS exec -i "$AMF_POD_NAME" -- /bin/tar cfz cn-pcap.tgz -C tmp pcap || true
    echo "kubectl -c tcpdump cp $NS/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap.tgz"
    kubectl -c tcpdump cp $NS/"$AMF_POD_NAME":cn-pcap.tgz "$prefix"/cn-pcap-"$DATE".tgz || true
}

#################################################################################

get-ran-pcap(){
    prefix=$1; shift

    DATE=$(date +"%Y-%m-%dT%H.%M.%S")

    if [[ $GNB_MODE = 'monolithic' ]]; then
	GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
	echo "Retrieve OAI5G gnb pcap file from the oai-gnb pod on ns $NS"
	echo "kubectl -c tcpdump -n $NS exec -i $GNB_POD_NAME -- /bin/tar cfz gnb-pcap.tgz -C tmp pcap"
	kubectl -c tcpdump -n $NS exec -i "$GNB_POD_NAME" -- /bin/tar cfz gnb-pcap.tgz -C tmp pcap || true
	echo "kubectl -c tcpdump cp $NS/$GNB_POD_NAME:gnb-pcap.tgz $prefix/gnb-pcap-$DATE.tgz"
	kubectl -c tcpdump cp $NS/"$GNB_POD_NAME":gnb-pcap.tgz "$prefix"/gnb-pcap-"$DATE".tgz || true
    else
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	echo "Retrieve OAI5G du pcap file from the oai-du pod on ns $NS"
	echo "kubectl -c tcpdump -n $NS exec -i $DU_POD_NAME -- /bin/tar cfz du-pcap.tgz -C tmp pcap"
	kubectl -c tcpdump -n $NS exec -i "$DU_POD_NAME" -- /bin/tar cfz du-pcap.tgz -C tmp pcap || true
	echo "kubectl -c tcpdump cp $NS/$DU_POD_NAME:du-pcap.tgz $prefix/du-pcap-$DATE.tgz"
	kubectl -c tcpdump cp $NS/"$GNB_POD_NAME":du-pcap.tgz "$prefix"/du-pcap-"$DATE".tgz || true
	if [[ $GNB_MODE = 'cudu' ]]; then
	    CU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[0].metadata.name}")
	    echo "Retrieve OAI5G cu pcap file from the oai-cu pod on ns $NS"
	    echo "kubectl -c tcpdump -n $NS exec -i $CU_POD_NAME -- /bin/tar cfz cu-pcap.tgz -C tmp pcap"
	    kubectl -c tcpdump -n $NS exec -i "$CU_POD_NAME" -- /bin/tar cfz cu-pcap.tgz -C tmp pcap || true
	    echo "kubectl -c tcpdump cp $NS/$CU_POD_NAME:cu-pcap.tgz $prefix/cu-pcap-$DATE.tgz"
	    kubectl -c tcpdump cp $NS/"$CU_POD_NAME":cu-pcap.tgz "$prefix"/cu-pcap-"$DATE".tgz || true
	else
	    CUCP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[0].metadata.name}")
	    echo "Retrieve OAI5G cucp pcap file from the oai-cu-cp pod on ns $NS"
	    echo "kubectl -c tcpdump -n $NS exec -i $CUCP_POD_NAME -- /bin/tar cfz cucp-pcap.tgz -C tmp pcap"
	    kubectl -c tcpdump -n $NS exec -i "$CUCP_POD_NAME" -- /bin/tar cfz cucp-pcap.tgz -C tmp pcap || true
	    echo "kubectl -c tcpdump cp $NS/$CUCP_POD_NAME:cucp-pcap.tgz $prefix/cucp-pcap-$DATE.tgz"
	    kubectl -c tcpdump cp $NS/"$CUCP_POD_NAME":cucp-pcap.tgz "$prefix"/cucp-pcap-"$DATE".tgz || true
	    CUUP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[0].metadata.name}")
	    echo "Retrieve OAI5G cuup pcap file from the oai-cu-up pod on ns $NS"
	    echo "kubectl -c tcpdump -n $NS exec -i $CUUP_POD_NAME -- /bin/tar cfz cuup-pcap.tgz -C tmp pcap"
	    kubectl -c tcpdump -n $NS exec -i "$CUUP_POD_NAME" -- /bin/tar cfz cuup-pcap.tgz -C tmp pcap || true
	    echo "kubectl -c tcpdump cp $NS/$CUUP_POD_NAME:cuup-pcap.tgz $prefix/cuup-pcap-$DATE.tgz"
	    kubectl -c tcpdump cp $NS/"$CUUP_POD_NAME":cuup-pcap.tgz "$prefix"/cuup-pcap-"$DATE".tgz || true
	fi
    fi
}

#################################################################################


get-all-pcap(){
    prefix=$1; shift

    get-cn-pcap "$prefix"
    get-ran-pcap "$prefix"
}


#################################################################################
#################################################################################
# Handle the different function calls 

if test $# -lt 1; then
    usage
else
    case $1 in
	start|stop|configure-all|start-cn|start-flexric|start-gnb|start-nr-ue|start-nr-ue2|start-nr-ue3|stop-cn|stop-flexric|stop-gnb|stop-nr-ue|stop-nr-ue2|stop-nr-ue3|run-ping)
	    echo "$0: running $1"
	    "$1"
	;;
	*)
	    usage
    esac
fi

