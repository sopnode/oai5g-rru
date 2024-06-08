#!/bin/bash

function usage() {
    echo "USAGE:"
    echo "demo-oai.sh init |"
    echo "            start |"
    echo "            stop |"
    echo "            configure-all |"
    echo "            start-cn |"
    echo "            start-gnb |"
    echo "            start-nr-ue |"
    echo "            stop-cn |"
    echo "            stop-gnb |"
    echo "            stop-nr-ue |"
    exit 1
}


#################################################################################
#################################################################################
# Following parameters automatically set by configure-demo-oai.sh script
# do not change them here !
NS="@DEF_NS@" # k8s namespace
NODE_AMF_UPF="@DEF_NODE_AMF_UPF@" # node in wich run amf and upf pods
NODE_GNB="@DEF_NODE_GNB@" # node in which gnb pod runs
RRU="@DEF_RRU@" # in ['b210', 'n300', 'n320', 'jaguar', 'panther', 'rfsim']
RUN_MODE="@DEF_RUN_MODE@" # in ['full', 'gnb-only', 'gnb-upf']
GNB_MODE="@DEF_GNB_MODE@" # in ['monolithic', 'cudu', 'cucpup']
LOGS="@DEF_LOGS@" # boolean, true if logs are retrieved on pods
PCAP="@DEF_PCAP@" # boolean, true if pcap are generated on pods
#
MCC="@DEF_MCC@"
MNC="@DEF_MNC@"
TAC="@DEF_TAC@"
DNN0="@DEF_DNN0@"
DNN1="@DEF_DNN1@"
SLICE1_SST="@DEF_SLICE1_SST@"
SLICE1_SD="@DEF_SLICE1_SD@"
SLICE1_5QI="@DEF_SLICE1_5QI@"
SLICE1_UPLINK="@DEF_SLICE1_UPLINK@"
SLICE1_DOWNLINK="@DEF_SLICE1_DOWNLINK@"
SLICE2_SST="@DEF_SLICE2_SST@"
SLICE2_SD="@DEF_SLICE2_SD@"
SLICE2_5QI="@DEF_SLICE2_5QI@"
SLICE2_UPLINK="@DEF_SLICE2_UPLINK@"
SLICE2_DOWNLINK="@DEF_SLICE2_DOWNLINK@"
GNB_ID="@DEF_GNB_ID@"
#
################SST0="@DEF_SST0@"
FULL_KEY="@DEF_FULL_KEY@"
OPC="@DEF_OPC@"
RFSIM_IMSI="@DEF_RFSIM_IMSI@"
#
PREFIX_DEMO="@DEF_PREFIX_DEMO@" # Directory in which all scripts will be copied on the k8s server to run the demo
#
#################################################################################
##################################################################################
TMP="/tmp/tmp.$USER"
mkdir -p $TMP
PREFIX_STATS="$TMP/oai5g-stats"
OAISA_REPO="docker.io/oaisoftwarealliance"

# Interfaces names of VLANs in sopnode servers
IF_NAME_VLAN100="net-100"
P100="192.168.100"
IF_NAME_VLAN10="net-10"
IF_NAME_VLAN20="net-20"


############# Running-mode dependent parameters configuration ###############
#

if [[ $RUN_MODE = "full" ]]; then
    # Local RAN, Local CN
    SUBNET_N2N3="192.168.128"
    NETMASK_N2N3="24"
    IF_NAME_N2N3="net-100"
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
    MULTUS_UPF_N6="false"
    IP_UPF_N6="" 
    NETMASK_UPF_N6=""
    GW_UPF_N6=""
    ROUTES_UPF_N6=""
    IF_NAME_UPF_N6=""
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
    MULTUS_GNB_N2="true"
    IP_GNB_N2="$SUBNET_N2N3.203"
    GNB_N2_IF_NAME="n2"
    MULTUS_GNB_N3="false"
    if [[ $GNB_MODE = 'cucpup' ]]; then
	IP_GNB_N3="$SUBNET_N2N3.204"
	IP_NRUE="$SUBNET_N2N3.205"
    else
	IP_GNB_N3="$IP_GNB_N2"
	IP_NRUE="$SUBNET_N2N3.204"
    fi
    GNB_N3_IF_NAME="n2"
    
else
    # Local RAN, External MYSQL/UDR/UDM/AUSF/AMF/SMF
    ENABLE_SNAT="off" # "yes" or "off"
    if [[ $RUN_MODE = "gnb-upf" ]]; then
	# Local RAN and local UPF
	SUBNET_N2N3="172.21.10"
	NETMASK_N2N3="26"
	IF_NAME_N2N3="br-slices"
	#
	ENABLED_MYSQL=false
	ENABLED_NRF=false
	NFS_NRF_HOST="$SUBNET_N2N3.203"
	ENABLED_NSSF=false
	ENABLED_UDR=false
	NFS_UDR_HOST="oai-udr"
	ENABLED_UDM=false
	NFS_UDM_HOST="oai-udm"
	ENABLED_AUSF=false
	NFS_AUSF_HOST="oai-ausf"
	# amf 
	ENABLED_AMF=false
	NFS_AMF_HOST="$SUBNET_N2N3.200"
	IP_AMF_N2="$SUBNET_N2N3.200"
	IF_N2="" # unused
	# smf
	ENABLED_SMF=false
	NFS_SMF_HOST="$SUBNET_N2N3.202"
	# upf
	ENABLED_UPF=true
	NFS_UPF_HOST="oai-upf"
	IF_SBI="n3"
	IF_N3="n3"
	IF_N4="n3"
	IF_N6="eth0"
	MULTUS_UPF_N3="true"
	IP_UPF_N3="$SUBNET_N2N3.222"
	NETMASK_UPF_N3="$NETMASK_N2N3"
	GW_UPF_N3=""
	ROUTES_UPF_N3="[{'dst': '10.8.0.0/24','gw': '172.21.10.254'}]"
	IF_NAME_UPF_N3="$IF_NAME_N2N3"
	MULTUS_UPF_N4="false"
	IP_UPF_N4="" 
	NETMASK_UPF_N4=""
	GW_UPF_N4=""
	ROUTES_UPF_N4=""
	IF_NAME_UPF_N4=""
	MULTUS_UPF_N6="false"
	IP_UPF_N6="" 
	NETMASK_UPF_N6=""
	GW_UPF_N6=""
	ROUTES_UPF_N6=""
	IF_NAME_UPF_N6=""
	
	# ran charts
	MULTUS_GNB_N2="true"
	IP_GNB_N2="$SUBNET_N2N3.223"
	GNB_N2_IF_NAME="n2"
	MULTUS_GNB_N3="false"
	if [[ $GNB_MODE = 'cucpup' ]]; then
	    IP_GNB_N3="$SUBNET_N2N3.224"
	    IP_NRUE="$SUBNET_N2N3.225"
	else
	    IP_GNB_N3="$IP_GNB_N2"
	    IP_NRUE="$SUBNET_N2N3.224"
	fi
	GNB_N3_IF_NAME="n2"
	ROUTES_GNB_N2="" # Set the route for gNB to reach AMF (N2) and UPF (N3)
	#ROUTES_GNB_N2="[{'dst': '172.21.0.0/16','gw': '192.168.128.129'},{'dst': '192.168.128.0/24','gw': '192.168.128.129'}]"
    else
        # RUN_MODE=gnb-only
	# -- Local RAN and external CN
        SUBNET_N2N3="172.21.10" # e.g., "10.0.20"
        NETMASK_N2N3="26"
        IF_NAME_N2N3="br-pepr" # e.g., "ran"
        # Set the external AMF IP address (N2)
        IP_AMF_N2="$SUBNET_N2N3.201"
        # Set the local gNB host network interface to reach AMF/UPF (N2/N3)
	MULTUS_GNB_N2="true"
	IP_GNB_N2="$SUBNET_N2N3.223"
	GNB_N2_IF_NAME="n2"
        # Set the route to reach AMF/UPF
        ROUTES_GNB_N2="" # [{'dst': '172.22.10.0/24','gw': '10.0.20.1'}]"
	MULTUS_GNB_N3="false"
	if [[ $GNB_MODE = 'cucpup' ]]; then
	    IP_GNB_N3="$SUBNET_N2N3.224"
	    IP_NRUE="$SUBNET_N2N3.225"
	else
	    IP_GNB_N3="$IP_GNB_N2"
	    IP_NRUE="$SUBNET_N2N3.224"
	fi
	GNB_N3_IF_NAME="n2"
    fi
fi



############################### oai-cn5g chart parameters ########################
#
OAI5G_CHARTS="$PREFIX_DEMO/oai-cn5g-fed/charts"
OAI5G_CORE="$OAI5G_CHARTS/oai-5g-core"
OAI5G_BASIC="$OAI5G_CORE/oai-5g-basic"
OAI5G_ADVANCE="$OAI5G_CORE/oai-5g-advance"

CN_DEFAULT_GW=""

################################ oai-gnb chart parameters ########################
OAI5G_RAN="$OAI5G_CHARTS/oai-5g-ran"
R2LAB_REPO="docker.io/r2labuser"
#
RAN_TAG="2024.w22"
GNB_NAME="gNB-r2lab"

#
# DU/CU SPLIT parameters
#
HOST_AMF="oai-amf"
NODE_CU="sopnode-w1-v100" # same node used for cu/cu-cp/cu-up

F1IFNAME="f1"
E1IFNAME="e1"
F1CUPORT="2152"
F1DUPORT="2152"
#
########## DU specific part ##############
#DU_REPO="${R2LAB_REPO}/oai-gnb" DU_REPO must be GNB_REPO to handle aw2s case
DU_TAG=${RAN_TAG}
NAME_DU_SA="oai-du-sa"
#
MULTUS_DU_F1="true"
IP_DU_F1="172.21.16.100"
NETMASK_DU_F1="22"
GW_DU_F1=""
ROUTES_DU_F1=""
IF_NAME_DU_F1="$IF_NAME_N2N3"
#
NAME_DU="oai-du"
CU_HOST="oai-cu"
QOS_DU_DEF="true"
NODE_DU="$NODE_GNB"
#
########## CU specific part ##############
CU_REPO="${R2LAB_REPO}/oai-gnb" 
CU_TAG=${RAN_TAG}
NAME_CU_SA="oai-cu-sa"
#
MULTUS_CU_F1="true"
IP_CU_F1="172.21.16.92"
NETMASK_CU_F1="22"
GW_CU_F1="" 
ROUTES_CU_F1="" 
IF_NAME_CU_F1="$IF_NAME_N2N3"
#
MULTUS_CU_N2="true"
IP_CU_N2="$IP_GNB_N2"  # "$SUBNET_N2N3.203" 
NETMASK_CU_N2="$NETMASK_N2N3"  # "24"
GW_CU_N2="" 
ROUTES_CU_N2=""
IF_NAME_CU_N2="$IF_NAME_N2N3"
#
MULTUS_CU_N3="false"
IP_CU_N3="" 
NETMASK_CU_N3=""
GW_CU_N3="" 
ROUTES_CU_N3=""
IF_NAME_CU_N3=""
#
ADD_OPTIONS_CU="--sa --log_config.global_log_options level,nocolor,time"
NAME_CU="oai-cu"
HOST_CU="oai-cu"
F1IFNAME="f1" 
N2IFNAME_CU="n2" 
N3IFNAME_CU="n2"
QOS_CU_DEF="true"
# NODE_CU is defined above and also the same for CUCP/CUUP
#
########## CU-CP specific part ##############
CUCP_REPO="${R2LAB_REPO}/oai-gnb" 
CUCP_TAG=${RAN_TAG}
NAME_CUCP_SA="oai-cu-cp-sa"
#
MULTUS_CUCP_E1="true"
IP_CUCP_E1="192.168.18.12"
NETMASK_CUCP_E1="24"
GW_CUCP_E1=""
ROUTES_CUCP_E1=""
IF_NAME_CUCP_E1="$IF_NAME_N2N3"
#
MULTUS_CUCP_N2="true"
IP_CUCP_N2="$IP_GNB_N2" # "$SUBNET_N2N3.203"
NETMASK_CUCP_N2="$NETMASK_N2N3" # "24"
GW_CUCP_N2=""
ROUTES_CUCP_N2=""
IF_NAME_CUCP_N2="$IF_NAME_N2N3"
#
MULTUS_CUCP_F1="true"
IP_CUCP_F1="172.21.16.92"
NETMASK_CUCP_F1="24"
GW_CUCP_F1=""
ROUTES_CUCP_F1=""
IF_NAME_CUCP_F1="$IF_NAME_N2N3"
#
ADD_OPTIONS_CUCP="--sa --log_config.global_log_options level,nocolor,time"
NAME_CUCP="oai-cu-cp"
N2IFNAME_CUCP="n2"
N3IFNAME_CUCP="n2"
QOS_CUCP_DEF="true"
NODE_CUCP="$NODE_CU"
#
########## CU-UP specific part ##############
CUUP_REPO="$R2LAB_REPO/oai-nr-cuup"
CUUP_TAG=${RAN_TAG}
NAME_CUUP_SA="oai-cu-up-sa"
#
MULTUS_CUUP_E1="true"
IP_CUUP_E1="192.168.18.13"
NETMASK_CUUP_E1="24"
GW_CUUP_E1=""
ROUTES_CUUP_E1="" 
IF_NAME_CUUP_E1="$IF_NAME_N2N3"
#
MULTUS_CUUP_N3="true"
IP_CUUP_N3="$IP_GNB_N3"
NETMASK_CUUP_N3="$NETMASK_N2N3" # "24"
GW_CUUP_N3="" 
ROUTES_CUUP_N3=""
IF_NAME_CUUP_N3="$IF_NAME_N2N3"  
#
MULTUS_CUUP_F1="true"
IP_CUUP_F1="172.21.16.93"
NETMASK_CUUP_F1="22"
GW_CUUP_F1="" # "172.21.19.254"
ROUTES_CUUP_F1=""
IF_NAME_CUUP_F1="$IF_NAME_N2N3"  
#
ADD_OPTIONS_CUUP="--sa"
NAME_CUUP="oai-cuup"
HOST_CUCP="oai-cu"
N2IFNAME_CUUP="n3"
N3IFNAME_CUUP="n3"
QOS_CUUP_DEF="true"
NODE_CUUP="$NODE_CU"
#
########## GNB Monolithic specific part ################
#
NETMASK_GNB_N2="$NETMASK_N2N3"
NETMASK_GNB_N3=""
NETMASK_GNB_RU="24"
#
################## RRU-dependent part ###################
#
#### rfsim RU case ####
#GNB_REPO_rfsim="${OAISA_REPO}/oai-gnb"
GNB_REPO_rfsim="${R2LAB_REPO}/oai-gnb"
GNB_TAG_rfsim="${RAN_TAG}"
CONF_rfsim="gnb.sa.band78.106prb.rfsim.conf" 
CONF_DU_rfsim="du.sa.band78.106prb.rfsim.conf" 
OPTIONS_rfsim="--sa -E --rfsim --log_config.global_log_options level,nocolor,time"
#
#### b2xx RU case ####
#GNB_REPO_b2xx="${OAISA_REPO}/oai-gnb"
GNB_REPO_b2xx="${R2LAB_REPO}/oai-gnb"
GNB_TAG_b2xx="${RAN_TAG}"
CONF_b210="gnb.sa.band78.fr1.106PRB.usrpb210.conf"
#CONF_b210="gnb.sa.band78.fr1.51PRB.usrpb210-new.conf"
#OPTIONS_b2xx="--sa --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"
OPTIONS_b2xx="--sa -E --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"

#### n3xx RU case ####
#GNB_REPO_n3xx="${OAISA_REPO}/oai-gnb"
GNB_REPO_n3xx="${R2LAB_REPO}/oai-gnb"
GNB_TAG_n3xx="${RAN_TAG}"
#
CONF_n320="gnb.sa.band78.106prb.usrpn310.ddsuu-2x2.conf"
CONF_DU_n320="du.sa.band78.106prb.usrpn310.ddsuu-2x2.conf"
CONF_n300="$CONF_n320"
CONF_DU_n300="$CONF_DU_n320"
#OPTIONS_n3xx="--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 0,2,4,6,8,10,12,14,16 --log_config.global_log_options level,nocolor,time"
OPTIONS_n3xx="--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --MACRLCs.[0].ul_max_mcs 14 --L1s.[0].max_ldpc_iterations 4 --log_config.global_log_options level,nocolor,time"
#
IP_GNB_SFP1="192.168.10.132"
IP_GNB_SFP2="192.168.20.132"
MTU_n3xx="9000"
IF_NAME_n3xx_1="$IF_NAME_VLAN10"
IF_NAME_n3xx_2="$IF_NAME_VLAN20"
ADDRS_n300="addr=192.168.10.129,second_addr=192.168.20.129"
ADDRS_n320="addr=192.168.10.130,second_addr=192.168.20.130"

#### aw2s RU case ####
#GNB_REPO_aw2s="${OAISA_REPO}/oai-gnb"
GNB_REPO_aw2s="${R2LAB_REPO}/oai-gnb-aw2s"
GNB_TAG_aw2s="${RAN_TAG}"
#
#CONF_jaguar="gnb.sa.band78.51prb.aw2s.ddsuu.20MHz.conf"
CONF_jaguar="gnb.sa.band78.133prb.aw2s.ddsuu.50MHz.conf"
CONF_DU_jaguar="du.sa.band78.133prb.aw2s.ddsuu.50MHz.conf"
CONF_panther="gnb.sa.band78.51prb.aw2s.ddsuu.20MHz.conf"
CONF_DU_panther="du.sa.band78.133prb.aw2s.ddsuu.50MHz.conf"
OPTIONS_aw2s="--sa --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"
IP_GNB_aw2s="$P100.243" 
IF_NAME_GNB_aw2s="$IF_NAME_VLAN100"
ADDR_jaguar="$P100.48" 
ADDR_panther="$P100.51"

########################### oai-nr-ue rfsim chart parameters #####################
OAI5G_NRUE="$OAI5G_CORE/oai-nr-ue"
NRUE_REPO="${OAISA_REPO}/oai-nr-ue"
NRUE_TAG="${RAN_TAG}"
OPTIONS_NRUE="--sa -E --rfsim -r 106 --numerology 1 -C 3319680000 --nokrnmod --log_config.global_log_options level,nocolor,time"
NETMASK_NRUE="$NETMASK_N2N3"
IF_NAME_NRUE="$IF_NAME_N2N3"
NRUE_USRP="rfsim"

##################################################################################

# Generate unique MAC addresses for multus interfaces in oai5g pods
function gener-mac()
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
	PREFIX="12:34:"
	case $IF_NAME_VLAN100 in
	    "net-100")
		PREFIX=$PREFIX"00:";;
	    *)  PREFIX=$PREFIX"01:";;
	esac
	case $NODE_AMF_UPF in
	    "sopnode-l1-v100")
		PREFIX=$PREFIX"00:";;
	    "sopnode-w1-v100")
		PREFIX=$PREFIX"01:";;
	    *)  PREFIX=$PREFIX"02:";;
	esac
	case $NODE_GNB in
	    "sopnode-l1-v100")
		PREFIX=$PREFIX"00:";;	
	    "sopnode-w1-v100")
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

##################################################################################

function init() {
    # init function should be run once per demo.

    # Install patch command...
    if [ ! -x "$(command -v patch)" ]; then
        [[ -f /etc/fedora-release ]] && dnf install -y patch
        [[ -f /etc/lsb-release ]] && apt-get install -y patch
    fi
}

#################################################################################

function configure-oai-5g-@mode@() {

    # if $LOGS is true, create a tcpdump container with privileges
    # if $PCAP is true, start tcpdump and create a shared volume to store pcap
    echo "Configuring chart $OAI5G_@MODE@/values.yaml for R2lab"
    cat > $TMP/@mode@-values.sed <<EOF
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
    cp "$OAI5G_@MODE@"/values.yaml $TMP/@mode@_values.yaml-orig
    echo "(Over)writing $OAI5G_@MODE@/values.yaml"
    sed -f $TMP/@mode@-values.sed < $TMP/@mode@_values.yaml-orig > "$OAI5G_@MODE@"/values.yaml
    diff $TMP/@mode@_values.yaml-orig "$OAI5G_@MODE@"/values.yaml

    echo "Configuring chart $OAI5G_@MODE@/config.yaml for R2lab"
    cat > $TMP/@mode@-config.sed <<EOF
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
s|@DNN1@|$DNN1|
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
    cp "$OAI5G_@MODE@"/config.yaml $TMP/@mode@_config.yaml-orig
    echo "(Over)writing $OAI5G_@MODE@/config.yaml"
    sed -f $TMP/@mode@-config.sed < $TMP/@mode@_config.yaml-orig > "$OAI5G_@MODE@"/config.yaml
    diff $TMP/@mode@_config.yaml-orig "$OAI5G_@MODE@"/config.yaml
    
    cd "$OAI5G_@MODE@"
    echo "helm dependency update"
    helm dependency update
}

#################################################################################

function configure-mysql() {

    DIR_ORIG_CHART="$OAI5G_CORE/mysql/initialization"
    DIR_PATCHED_CHART="$PREFIX_DEMO/oai5g-rru/patch-mysql"

    echo "configure-mysql: mysql database already patched by configure-demo-oai.sh script, just copy it"
    echo "cp $DIR_PATCHED_CHART/oai_db-basic.sql $DIR_ORIG_CHART/"
    cp $DIR_PATCHED_CHART/oai_db-basic.sql $DIR_ORIG_CHART/
}

#################################################################################


function configure-gnb() {

    # Prepare mounted.conf and gnb chart files
    echo "configure-gnb: gNB on node $NODE_GNB with RRU $RRU and logs is $LOGS"

    DIR_RAN="$PREFIX_DEMO/oai5g-rru/ran-config"
    DIR_CONF="$DIR_RAN/conf"
    DIR_CHARTS="$PREFIX_DEMO/oai-cn5g-fed/charts"

    SED_CONF_FILE="$TMP/gnb_conf.sed"
    SED_VALUES_FILE="$TMP/oai-gnb-values.sed"

    # Configure RRU specific parameters for values.yaml chart
    if [[ "$RRU" = "b210" ]]; then
	MULTUS_GNB_RU1="false"
	MULTUS_GNB_RU2="false"
	RRU_TYPE="b2xx"
	ADD_OPTIONS_GNB="$OPTIONS_b2xx"
	QOS_GNB_DEF="false"

    elif [[ "$RRU" = "n300" || "$RRU" = "n320" ]]; then
	SDR_ADDRS=$(eval echo \"\${ADDRS_$RRU}\")
	MULTUS_GNB_RU1="true"
	IP_GNB_RU1="$IP_GNB_SFP1"
	MTU_GNB_RU1="$MTU_n3xx"
	IF_NAME_GNB_RU1="$IF_NAME_n3xx_1"
	MULTUS_GNB_RU2="true"
	IP_GNB_RU2="$IP_GNB_SFP2"
	MTU_GNB_RU2="$MTU_n3xx"
	IF_NAME_GNB_RU2="$IF_NAME_n3xx_2"
	RRU_TYPE="n3xx"
	ADD_OPTIONS_GNB="$OPTIONS_n3xx"
	QOS_GNB_DEF="true"

    elif [[ "$RRU" = "jaguar" || "$RRU" = "panther" ]]; then
	ADDR_aw2s=$(eval echo \"\${ADDR_$RRU}\")
	GNB_aw2s_LOCAL_IF_NAME="ru1"
	MULTUS_GNB_RU1="true"
	IP_GNB_RU1="$IP_GNB_aw2s"
	IF_NAME_GNB_RU1="$IF_NAME_GNB_aw2s"
	MULTUS_GNB_RU2="false"
	RRU_TYPE="aw2s"
	ADD_OPTIONS_GNB="$OPTIONS_aw2s"
	QOS_GNB_DEF="true"
	
    elif [[ "$RRU" = "rfsim" ]]; then
	MULTUS_GNB_RU1="false"
	MULTUS_GNB_RU2="false"
	RRU_TYPE="rfsim"
	ADD_OPTIONS_GNB="$OPTIONS_rfsim"
	QOS_GNB_DEF="false"

    else
	echo "Unknown rru selected: $RRU"
	usage
    fi
    
    GNB_REPO=$(eval echo \"\${GNB_REPO_$RRU_TYPE}\")
    GNB_TAG=$(eval echo \"\${GNB_TAG_$RRU_TYPE}\")
    GNB_NAME="${GNB_NAME}_${RRU}"
    NAME_GNB_DU="${NAME_GNB_DU}-${RRU}"

    if [[ $GNB_MODE = 'monolithic' ]]; then
	CONF_ORIG=$DIR_CONF/$(eval echo \"\${CONF_$RRU}\")
	DIR_TEMPLATES="$PREFIX_DEMO/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb/templates"
	NB_LINES=8
	echo "monolithic gNB, conf is $CONF_ORIG"
    else
	CONF_ORIG=$DIR_CONF/$(eval echo \"\${CONF_DU_$RRU}\")
	DIR_TEMPLATES="$PREFIX_DEMO/oai-cn5g-fed/charts/oai-5g-ran/oai-du/templates"
	NB_LINES=7
	echo "DU gNB, conf is $CONF_ORIG"
    fi
    
    echo "Insert the right gNB conf file $CONF_ORIG in the right configmap.yaml"
    # Keep the 8 first lines of configmap.yaml
    head -${NB_LINES}  "$DIR_TEMPLATES"/configmap.yaml > $TMP/configmap.yaml
    # Add a 6-characters margin to gnb.conf
    awk '$0="      "$0' "$CONF_ORIG" > $TMP/gnb.conf
    # Append the modified gnb.conf to $TMP/configmap.yaml
    cat $TMP/gnb.conf >> $TMP/configmap.yaml

    echo "Configure gnb parameters within configmap.yaml"
    PLMN_LIST="({ mcc = $MCC; mnc = $MNC; mnc_length = 2; snssaiList = ({ sst = $SLICE1_SST; sd = $SLICE1_SD }) });"
    mv $TMP/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml

    cat > "$SED_CONF_FILE" <<EOF
s|@GNB_NAME@|$GNB_NAME|
s|@GNB_ID@|$GNB_ID|
s|@GNB_CU_UP_ID@|$GNB_ID|
s|@GNB_DU_ID@|$GNB_ID|
s|@TAC@|$TAC|
s|plmn_list.*|plmn_list = $PLMN_LIST|
s|@GNB_N2_IF_NAME@|$GNB_N2_IF_NAME|
s|@GNB_N2_IP_ADDRESS@|$IP_GNB_N2/$NETMASK_N2N3|
s|@CU_UP_N2_IP_ADDRESS@|$IP_CUUP_N3|
s|@GNB_N3_IF_NAME@|$GNB_N3_IF_NAME|
s|@GNB_N3_IP_ADDRESS@|$IP_GNB_N3/$NETMASK_N2N3|
s|@CU_UP_N3_IP_ADDRESS@|$IP_CUUP_N3|
s|@AW2S_IP_ADDRESS@|$ADDR_aw2s|
s|@GNB_AW2S_IP_ADDRESS@|$IP_GNB_aw2s|
s|@GNB_AW2S_LOCAL_IF_NAME@|$GNB_aw2s_LOCAL_IF_NAME|
s|@SDR_ADDRS@|$SDR_ADDRS,clock_source=internal,time_source=internal|
EOF

    if [[ $GNB_MODE != 'monolithic' ]]; then
	echo "With cudu/cucpup modes, set here AMF_IP_ADDRESS, CUCP_IP_ADDRESS and CU_IP_ADDRESS"
	cat >> "$SED_CONF_FILE" <<EOF
s|@AMF_IP_ADDRESS@|$IP_AMF_N2|
s|@CU_IP_ADDRESS@|$IP_CU_F1|
s|@CU_CP_IP_ADDRESS@|$IP_CUCP_E1|
EOF
    else
	echo "Monolithic mode, do not set AMF_IP_ADDRESS and CU_IP_ADDRESS"
    fi
    
    for nf in oai-gnb oai-du oai-cu oai-cu-cp oai-cu-up; do
	ORIG_CHART="${OAI5G_RAN}/${nf}/templates/configmap.yaml"
	cp ${ORIG_CHART} $TMP/${nf}_configmap.yaml-orig
	echo "(Over)writing $ORIG_CHART"
	sed -f "$SED_CONF_FILE" < $TMP/${nf}_configmap.yaml-orig > ${ORIG_CHART}
	echo "********************* Display modified ${ORIG_CHART} ************************"
	cat ${ORIG_CHART}
    done


    # Configure gNB values.yaml charts

    echo "Then configure gNB charts"
    cat > "$SED_VALUES_FILE" <<EOF
s|@GNB_REPO@|$GNB_REPO|
s|@GNB_TAG@|$GNB_TAG|
s|@DEFAULT_GW_GNB@|$DEFAULT_GW_GNB|
s|@MULTUS_GNB_N2@|$MULTUS_GNB_N2|
s|@AMF_IP_ADDRESS@|$IP_AMF_N2|
s|@IP_GNB_N2@|$IP_GNB_N2|
s|@NETMASK_GNB_N2@|$NETMASK_GNB_N2|
s|@MAC_GNB_N2@|$(gener-mac)|
s|@GW_GNB_N2@|$GW_GNB_N2|
s|@ROUTES_GNB_N2@|$ROUTES_GNB_N2|
s|@IF_NAME_GNB_N2@|$IF_NAME_N2N3|
s|@MULTUS_GNB_N3@|$MULTUS_GNB_N3|
s|@IP_GNB_N3@|$IP_GNB_N3|
s|@NETMASK_GNB_N3@|$NETMASK_GNB_N3|
s|@MAC_GNB_N3@|$(gener-mac)|
s|@GW_GNB_N3@|$GW_GNB_N3|
s|@ROUTES_GNB_N3@|$ROUTES_GNB_N3|
s|@IF_NAME_GNB_N3@|$IF_NAME_N2N3|
s|@MULTUS_GNB_RU1@|$MULTUS_GNB_RU1|
s|@IP_GNB_RU1@|$IP_GNB_RU1|
s|@NETMASK_GNB_RU1@|$NETMASK_GNB_RU|
s|@MAC_GNB_RU1@|$(gener-mac)|
s|@GW_GNB_RU1@|$GW_GNB_RU1|
s|@MTU_GNB_RU1@|$MTU_GNB_RU1|
s|@IF_NAME_GNB_RU1@|$IF_NAME_GNB_RU1|
s|@MULTUS_GNB_RU2@|$MULTUS_GNB_RU2|
s|@IP_GNB_RU2@|$IP_GNB_RU2|
s|@NETMASK_GNB_RU2@|$NETMASK_GNB_RU|
s|@MAC_GNB_RU2@|$(gener-mac)|
s|@GW_GNB_RU2@|$GW_GNB_RU2|
s|@MTU_GNB_RU2@|$MTU_GNB_RU2|
s|@IF_NAME_GNB_RU2@|$IF_NAME_GNB_RU2|
s|@RRU_TYPE@|$RRU_TYPE|
s|@ADD_OPTIONS_GNB@|$ADD_OPTIONS_GNB|
s|@GNB_NAME@|$GNB_NAME|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@TAC@|$TAC|
s|@GNB_N2_IF_NAME@|$GNB_N2_IF_NAME|
s|@GNB_N3_IF_NAME@|$GNB_N3_IF_NAME|
s|@START_TCPDUMP@|$PCAP|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@SHAREDVOLUME@|$PCAP|
s|@QOS_GNB_DEF@|$QOS_GNB_DEF|
s|@NODE_GNB@|$NODE_GNB|

s|@F1IFNAME@|$F1IFNAME|
s|@E1IFNAME@|$E1IFNAME|
s|@F1CUPORT@|$F1CUPORT|
s|@F1DUPORT@|$F1DUPORT|

s|@DU_REPO@|$GNB_REPO|
s|@DU_TAG@|$DU_TAG|
s|@NAME_DU_SA@|$NAME_DU_SA|
s|@MULTUS_DU_F1@|$MULTUS_DU_F1|
s|@IP_DU_F1@|$IP_DU_F1|
s|@NETMASK_DU_F1@|$NETMASK_DU_F1|
s|@MAC_DU_F1@|$(gener-mac)|
s|@GW_DU_F1@|$GW_DU_F1|
s|@ROUTES_DU_F1@|$ROUTES_DU_F1|
s|@IF_NAME_DU_F1@|$IF_NAME_DU_F1|
s|@NAME_DU@|$NAME_DU|
s|@CU_HOST@|$CU_HOST|
s|@QOS_DU_DEF@|$QOS_DU_DEF|
s|@NODE_DU@|$NODE_DU|

s|@CU_REPO@|$CU_REPO|
s|@CU_TAG@|$CU_TAG|
s|@NAME_CU_SA@|$NAME_CU_SA|
s|@MULTUS_CU_F1@|$MULTUS_CU_F1|
s|@IP_CU_F1@|$IP_CU_F1|
s|@NETMASK_CU_F1@|$NETMASK_CU_F1|
s|@MAC_CU_F1@|$(gener-mac)|
s|@GW_CU_F1@|$GW_CU_F1|
s|@ROUTES_CU_F1@|$ROUTES_CU_F1|
s|@IF_NAME_CU_F1@|$IF_NAME_CU_F1|
s|@MULTUS_CU_N2@|$MULTUS_CU_N2|
s|@IP_CU_N2@|$IP_CU_N2|
s|@NETMASK_CU_N2@|$NETMASK_CU_N2|
s|@MAC_CU_N2@|$(gener-mac)|
s|@GW_CU_N2@|$GW_CU_N2|
s|@ROUTES_CU_N2@|$ROUTES_CU_N2|
s|@IF_NAME_CU_N2@|$IF_NAME_CU_N2|
s|@MULTUS_CU_N3@|$MULTUS_CU_N3|
s|@IP_CU_N3@|$IP_CU_N3|
s|@NETMASK_CU_N3@|$NETMASK_CU_N3|
s|@MAC_CU_N3@|$(gener-mac)|
s|@GW_CU_N3@|$GW_CU_N3|
s|@ROUTES_CU_N3@|$ROUTES_CU_N3|
s|@IF_NAME_CU_N3@|$IF_NAME_CU_N3|
s|@ADD_OPTIONS_CU@|$ADD_OPTIONS_CU|
s|@NAME_CU@|$NAME_CU|
s|@HOST_AMF@|$HOST_AMF|
s|@HOST_CU@|$HOST_CU|
s|@N2IFNAME_CU@|$N2IFNAME_CU|
s|@N3IFNAME_CU@|$N3IFNAME_CU|
s|@QOS_CU_DEF@|$QOS_CU_DEF|
s|@NODE_CU@|$NODE_CU|

s|@CUCP_REPO@|$CUCP_REPO|
s|@CUCP_TAG@|$CUCP_TAG|
s|@NAME_CUCP_SA@|$NAME_CUCP_SA|
s|@MULTUS_CUCP_E1@|$MULTUS_CUCP_E1|
s|@IP_CUCP_E1@|$IP_CUCP_E1|
s|@NETMASK_CUCP_E1@|$NETMASK_CUCP_E1|
s|@MAC_CUCP_E1@|$(gener-mac)|
s|@GW_CUCP_E1@|$GW_CUCP_E1|
s|@ROUTES_CUCP_E1@|$ROUTES_CUCP_E1|
s|@IF_NAME_CUCP_E1@|$IF_NAME_CUCP_E1|
s|@MULTUS_CUCP_N2@|$MULTUS_CUCP_N2|
s|@IP_CUCP_N2@|$IP_CUCP_N2|
s|@NETMASK_CUCP_N2@|$NETMASK_CUCP_N2|
s|@MAC_CUCP_N2@|$(gener-mac)|
s|@GW_CUCP_N2@|$GW_CUCP_N2|
s|@ROUTES_CUCP_N2@|$ROUTES_CUCP_N2|
s|@IF_NAME_CUCP_N2@|$IF_NAME_CUCP_N2|
s|@MULTUS_CUCP_F1@|$MULTUS_CUCP_F1|
s|@IP_CUCP_F1@|$IP_CUCP_F1|
s|@NETMASK_CUCP_F1@|$NETMASK_CUCP_F1|
s|@MAC_CUCP_F1@|$(gener-mac)|
s|@GW_CUCP_F1@|$GW_CUCP_F1|
s|@ROUTES_CUCP_F1@|$ROUTES_CUCP_F1|
s|@IF_NAME_CUCP_F1@|$IF_NAME_CUCP_F1|
s|@ADD_OPTIONS_CUCP@|$ADD_OPTIONS_CUCP|
s|@NAME_CUCP@|$NAME_CUCP|
s|@N2IFNAME_CUCP@|$N2IFNAME_CUCP|
s|@N3IFNAME_CUCP@|$N3IFNAME_CUCP|
s|@QOS_CUCP_DEF@|$QOS_CUCP_DEF|
s|@NODE_CUCP@|$NODE_CUCP|

s|@CUUP_REPO@|$CUUP_REPO|
s|@CUUP_TAG@|$CUUP_TAG|
s|@NAME_CUUP_SA@|$NAME_CUUP_SA|
s|@MULTUS_CUUP_E1@|$MULTUS_CUUP_E1|
s|@IP_CUUP_E1@|$IP_CUUP_E1|
s|@NETMASK_CUUP_E1@|$NETMASK_CUUP_E1|
s|@MAC_CUUP_E1@|$(gener-mac)|
s|@GW_CUUP_E1@|$GW_CUUP_E1|
s|@ROUTES_CUUP_E1@|$ROUTES_CUUP_E1|
s|@IF_NAME_CUUP_E1@|$IF_NAME_CUUP_E1|
s|@MULTUS_CUUP_N3@|$MULTUS_CUUP_N3|
s|@IP_CUUP_N3@|$IP_CUUP_N3|
s|@NETMASK_CUUP_N3@|$NETMASK_CUUP_N3|
s|@MAC_CUUP_N3@|$(gener-mac)|
s|@GW_CUUP_N3@|$GW_CUUP_N3|
s|@ROUTES_CUUP_N3@|$ROUTES_CUUP_N3|
s|@IF_NAME_CUUP_N3@|$IF_NAME_CUUP_N3|
s|@MULTUS_CUUP_F1@|$MULTUS_CUUP_F1|
s|@IP_CUUP_F1@|$IP_CUUP_F1|
s|@NETMASK_CUUP_F1@|$NETMASK_CUUP_F1|
s|@MAC_CUUP_F1@|$(gener-mac)|
s|@GW_CUUP_F1@|$GW_CUUP_F1|
s|@ROUTES_CUUP_F1@|$ROUTES_CUUP_F1|
s|@IF_NAME_CUUP_F1@|$IF_NAME_CUUP_F1|
s|@ADD_OPTIONS_CUUP@|$ADD_OPTIONS_CUUP|
s|@NAME_CUUP@|$NAME_CUUP|
s|@HOST_CUCP@|$HOST_CUCP|
s|@N2IFNAME_CUUP@|$N2IFNAME_CUUP|
s|@N3IFNAME_CUUP@|$N3IFNAME_CUUP|
s|@QOS_CUUP_DEF@|$QOS_CUUP_DEF|
s|@NODE_CUUP@|$NODE_CUUP|
EOF
    for nf in oai-gnb oai-du oai-cu oai-cu-cp oai-cu-up; do
	ORIG_CHART="${OAI5G_RAN}/${nf}/values.yaml"
	cp ${ORIG_CHART} $TMP/${nf}_values.yaml-orig
	echo "(Over)writing $ORIG_CHART"
	sed -f "$SED_VALUES_FILE" < $TMP/${nf}_values.yaml-orig > ${ORIG_CHART}
	diff $TMP/${nf}_values.yaml-orig ${ORIG_CHART}
    done
}

#################################################################################

function configure-nr-ue() {

    # will NOT generate PCAP file to avoid wasting all memory resources
    # However, a tcpdump container created e.g., to run iperf client"
    DIR="$OAI5G_RAN/oai-nr-ue"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="$TMP/oai-nr-ue-values.sed"
    echo "configure-nr-ue: $ORIG_CHART configuration"
    ADD_OPTIONS_NRUE="$OPTIONS_NRUE"
    cat > "$SED_FILE" <<EOF
s|@NRUE_REPO@|$NRUE_REPO|
s|@NRUE_TAG@|$NRUE_TAG|
s|@MULTUS_NRUE@|true|
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
s|@SD@|$SLICE1_SD|
s|@NRUE_USRP@|$NRUE_USRP|
s|@ADD_OPTIONS_NRUE@|$ADD_OPTIONS_NRUE|
s|@START_TCPDUMP@|false|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@QOS_NRUE_DEF@|false|
s|@SHAREDVOLUME@|false|
s|@NODE_NRUE@||
EOF
    cp "$ORIG_CHART" $TMP/oai-nr-ue_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < $TMP/oai-nr-ue_values.yaml-orig > "$ORIG_CHART"
    diff $TMP/oai-nr-ue_values.yaml-orig "$ORIG_CHART"
}


#################################################################################

function configure-all() {
    echo "configure-all: Applying SophiaNode patches to OAI5G charts located on "$PREFIX_DEMO"/oai-cn5g-fed"
    echo -e "\t with oai-upf running on $NODE_AMF_UPF"
    echo -e "\t with oai-gnb running on $NODE_GNB"
    echo -e "\t with generate-logs: $LOGS"
    echo -e "\t with generate-pcap: $PCAP"

    # Remove pulling limitations from docker-hub with anonymous account
    echo "Create $NS if not present and regcred secret"	     
    kubectl create namespace $NS || true
    kubectl -n $NS delete secret regcred || true
    kubectl -n $NS create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=@DEF_REGCRED_NAME@ --docker-password=@DEF_REGCRED_PWD@ --docker-email=@DEF_REGCRED_EMAIL@ || true

    # Ensure that helm spray plugin is installed
    configure-oai-5g-@mode@ 
    configure-mysql
    configure-gnb
    if [[ "$RRU" = "rfsim" ]]; then
	configure-nr-ue
    fi
}

#################################################################################


function start-cn() {
    echo "Running start-cn() with namespace=$NS, NODE_AMF_UPF=$NODE_AMF_UPF"
    echo "cd $OAI5G_@MODE@"
    cd "$OAI5G_@MODE@"

    echo "helm dependency update"
    helm dependency update

    echo "helm --namespace=$NS install oai-5g-@mode@ ."
    helm --create-namespace --namespace=$NS install oai-5g-@mode@ .

    echo "Wait until all 5G Core pods are READY"
    kubectl wait pod -n $NS --for=condition=Ready --all
}

#################################################################################


function start-gnb() {
    echo "Running gNB on $NS namespace with GNB_MODE=$GNB_MODE, NODE_GNB=$NODE_GNB and rru=$RRU"

    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    if [[ $GNB_MODE = 'monolithic' ]]; then
	echo "helm -n $NS install oai-gnb oai-gnb/"
	helm -n $NS install oai-gnb oai-gnb/
	echo "Wait until the gNB pod is READY"
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
    echo "kubectl -n $NS wait pod --for=condition=Ready --all"
    kubectl -n $NS wait pod --for=condition=Ready --all
}

#################################################################################

function start-nr-ue() {

    echo "Running start-nr-ue() on namespace: $NS, NODE_GNB=$NODE_GNB"
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    echo "retrieve gNB/DU IP"
    if [[ $GNB_MODE != 'monolithic' ]]; then
	GNB_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
    else
	GNB_IP=${IP_GNB_N2} 
    fi
    echo "sed -i "s/@IP_GNB@/$GNB_IP/" ${OAI5G_RAN}/oai-nr-ue/values.yaml"
    sed -i "s/@IP_GNB@/$GNB_IP/" ${OAI5G_RAN}/oai-nr-ue/values.yaml

    echo "helm -n $NS install oai-nr-ue oai-nr-ue/" 
    helm -n $NS install oai-nr-ue oai-nr-ue/

    echo "Wait until oai-nr-ue pod is READY"
    kubectl wait pod -n $NS --for=condition=Ready --all
}


#################################################################################

function start() {
    echo "start: run all oai5g pods on namespace=$NS"

    if [[ $LOGS = "true" ]]; then
	echo "start: Create a k8s persistence volume for generation of RAN logs files"
	cat << \EOF >> $TMP/oai5g-pv.yaml
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
	kubectl apply -f $TMP/oai5g-pv.yaml

	echo "start: Create a k8s persistence volume for generation of CN logs files"
	cat << \EOF >> $TMP/cn5g-pv.yaml
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
	kubectl apply -f $TMP/cn5g-pv.yaml

	
	echo "start: Create a k8s persistent volume claim for RAN logs files"
    cat << \EOF >> $TMP/oai5g-pvc.yaml
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
    echo "kubectl -n $NS apply -f $TMP/oai5g-pvc.yaml"
    kubectl -n $NS apply -f $TMP/oai5g-pvc.yaml

	echo "start: Create a k8s persistent volume claim for CN logs files"
    cat << \EOF >> $TMP/cn5g-pvc.yaml
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
    echo "kubectl -n $NS apply -f $TMP/cn5g-pvc.yaml"
    kubectl -n $NS apply -f $TMP/cn5g-pvc.yaml
    fi

    if [[ "$RUN_MODE" != "gnb-only" ]]; then
	start-cn 
    fi
    start-gnb 

    if [[ "$RRU" == "rfsim" ]]; then
	echo "sleep 5s before starting nr-ue"; sleep 5
	start-nr-ue 
    fi

    echo "****************************************************************************"
    echo "When you finish, to clean-up the k8s cluster, please run demo-oai.py --clean"
}

#################################################################################

function run-ping() {
    UE_POD_NAME=$(kubectl -n $NS get pods -l app.kubernetes.io/name=oai-nr-ue -o jsonpath="{.items[0].metadata.name}")
    echo "kubectl -n $NS exec -it $UE_POD_NAME -c nr-ue -- /bin/ping --I oaitun_ue1 c4 google.fr"
    kubectl -n $NS exec -it $UE_POD_NAME -c nr-ue -- /bin/ping -I oaitun_ue1 -c4 google.fr
}

#################################################################################

function stop-cn(){
    echo "helm --namespace=$NS uninstall oai-5g-@mode@"
    helm --namespace=$NS uninstall oai-5g-@mode@ 
}


function stop-gnb(){
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


function stop-nr-ue(){
    echo "helm -n $NS uninstall oai-nr-ue"
    helm -n $NS uninstall oai-nr-ue
}


function stop() {
    echo "Running stop() on $NS namespace, logs=$LOGS"

    if [[ "$LOGS" = "true" ]]; then
	dir_stats=${PREFIX_STATS-"$TMP/oai5g-stats"}
	echo "First retrieve all pcap and logs files in $dir_stats and compressed it"
	mkdir -p $dir_stats
	echo "cleanup $dir_stats before including new logs/pcap files"
	cd $dir_stats; rm -f *.pcap *.tgz *.logs *stats* *.conf
	if [[ "$PCAP" = "true" ]]; then
	    get-all-pcap $dir_stats
	fi
	get-all-logs $dir_stats
	cd $TMP; dirname=$(basename $dir_stats)
	echo tar cfz "$dirname".tgz $dirname
	tar cfz "$dirname".tgz $dirname
    fi

    res=$(helm -n $NS ls | wc -l)
    if test $res -gt 1; then
        echo "Remove all 5G OAI pods"
	if [[ "$RUN_MODE" != "gnb-only" ]]; then
	    stop-cn
	fi
	stop-gnb
	if [[ "$RRU" = "rfsim" ]]; then
	    stop-nr-ue
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


function get-all-logs() {
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    echo "get-all-logs: saving charts"
    tar -C "$PREFIX_DEMO/oai-cn5g-fed" -cf "$prefix"/charts.tar charts


    AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    AMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-amf $AMF_POD_NAME running with IP $AMF_eth0_IP"
    kubectl --namespace $NS -c amf logs $AMF_POD_NAME > "$prefix"/amf-"$DATE".logs

    AUSF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    AUSF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-ausf $AUSF_POD_NAME running with IP $AUSF_eth0_IP"
    kubectl --namespace $NS -c ausf logs $AUSF_POD_NAME > "$prefix"/ausf-"$DATE".logs

    NRF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    NRF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-nrf $NRF_POD_NAME running with IP $NRF_eth0_IP"
    kubectl --namespace $NS -c nrf logs $NRF_POD_NAME > "$prefix"/nrf-"$DATE".logs

    SMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    SMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-smf $SMF_POD_NAME running with IP $SMF_eth0_IP"
    kubectl --namespace $NS -c smf logs $SMF_POD_NAME > "$prefix"/smf-"$DATE".logs

    UPF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-upf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UPF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-upf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-upf $UPF_POD_NAME running with IP $UPF_eth0_IP"
    kubectl --namespace $NS -c upf logs $UPF_POD_NAME > "$prefix"/upf-"$DATE".logs

    UDM_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UDM_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-udm $UDM_POD_NAME running with IP $UDM_eth0_IP"
    kubectl --namespace $NS -c udm logs $UDM_POD_NAME > "$prefix"/udm-"$DATE".logs
    
    UDR_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UDR_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-udr $UDR_POD_NAME running with IP $UDR_eth0_IP"
    kubectl --namespace $NS -c udr logs $UDR_POD_NAME > "$prefix"/udr-"$DATE".logs

    if [[ $GNB_MODE = 'monolithic' ]]; then
	GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
	GNB_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-gnb $GNB_POD_NAME running with IP $GNB_eth0_IP"
	kubectl --namespace $NS -c gnb logs $GNB_POD_NAME > "$prefix"/gnb-"$DATE".logs
	echo "Retrieve gnb config from the pod"
	kubectl -c gnb cp $NS/$GNB_POD_NAME:/tmp/gnb.conf $prefix/gnb.conf || true
	echo "Retrieve nrL1_stats.log, nrMAC_stats.log and nrRRC_stats.log from gnb pod"
	kubectl -c gnb cp $NS/$GNB_POD_NAME:nrL1_stats.log $prefix/nrL1_stats.log"$DATE" || true
	kubectl -c gnb cp $NS/$GNB_POD_NAME:nrMAC_stats.log $prefix/nrMAC_stats.log"$DATE" || true
	kubectl -c gnb cp $NS/$GNB_POD_NAME:nrRRC_stats.log $prefix/nrRRC_stats.log"$DATE" || true
    elif [[ $GNB_MODE = 'cudu' ]]; then
	CU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[0].metadata.name}")
	CU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-cu $CU_POD_NAME running with IP $CU_eth0_IP"
	kubectl --namespace $NS -c gnbcu logs $CU_POD_NAME > "$prefix"/cu-"$DATE".logs
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	kubectl -c gnbdu cp $NS/$DU_POD_NAME:nrL1_stats.log $prefix/nrL1_stats.log"$DATE" || true
	kubectl -c gnbdu cp $NS/$DU_POD_NAME:nrMAC_stats.log $prefix/nrMAC_stats.log"$DATE" || true
	kubectl -c gnbcu cp $NS/$CU_POD_NAME:nrRRC_stats.log $prefix/nrRRC_stats.log"$DATE" || true
	DU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-du $DU_POD_NAME running with IP $DU_eth0_IP"
	kubectl --namespace $NS -c gnbdu logs $DU_POD_NAME > "$prefix"/du-"$DATE".logs
	echo "Retrieve cu/du configs from the pods"
	kubectl -c gnbcu cp $NS/$CU_POD_NAME:/tmp/cu.conf $prefix/cu.conf || true
	kubectl -c gnbdu cp $NS/$DU_POD_NAME:/tmp/du.conf $prefix/du.conf || true
    else
	# $GNB_MODE = 'cucpup'
	CUCP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[0].metadata.name}")
	CUCP_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-cu-cp $CUCP_POD_NAME running with IP $CUCP_eth0_IP"
	kubectl --namespace $NS -c gnbcucp logs $CUCP_POD_NAME > "$prefix"/cucp-"$DATE".logs
	CUUP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[0].metadata.name}")
	CUUP_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-cu-up $CUUP_POD_NAME running with IP $CUUP_eth0_IP"
	kubectl --namespace $NS -c gnbcuup logs $CUUP_POD_NAME > "$prefix"/cuup-"$DATE".logs
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	kubectl -c gnbdu cp $NS/$DU_POD_NAME:nrL1_stats.log $prefix/nrL1_stats.log"$DATE" || true
	kubectl -c gnbdu cp $NS/$DU_POD_NAME:nrMAC_stats.log $prefix/nrMAC_stats.log"$DATE" || true
	kubectl -c gnbcucp cp $NS/$CUCP_POD_NAME:nrRRC_stats.log $prefix/nrRRC_stats.log"$DATE" || true
	DU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-du $DU_POD_NAME running with IP $DU_eth0_IP"
	kubectl --namespace $NS -c gnbdu logs $DU_POD_NAME > "$prefix"/du-"$DATE".logs
	echo "Retrieve cucp/cuup/du configs from the pods"
	kubectl -c gnbcucp cp $NS/$CUCP_POD_NAME:/tmp/cucp.conf $prefix/cucp.conf || true
	kubectl -c gnbcuup cp $NS/$CUUP_POD_NAME:/tmp/cuup.conf $prefix/cuup.conf || true
	kubectl -c gnbdu cp $NS/$DU_POD_NAME:/tmp/du.conf $prefix/du.conf || true
    fi

    if [[ "$RRU" = "rfsim" ]]; then
	NRUE_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
	NRUE_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-nr-ue $NRUE_POD_NAME running with IP $NRUE_eth0_IP"
	kubectl --namespace $NS -c nr-ue logs $NRUE_POD_NAME > "$prefix"/nr-ue-"$DATE".logs
    fi

}

#################################################################################

function get-cn-pcap(){
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G CN pcap files from the AMF pod on ns $NS"
    echo "kubectl -c tcpdump -n $NS exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz -C tmp pcap"
    kubectl -c tcpdump -n $NS exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz -C tmp pcap || true
    echo "kubectl -c tcpdump cp $NS/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap.tgz"
    kubectl -c tcpdump cp $NS/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap-"$DATE".tgz || true
}

#################################################################################

function get-ran-pcap(){
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G gnb pcap file from the oai-gnb pod on ns $NS"
    echo "kubectl -c tcpdump -n $NS exec -i $GNB_POD_NAME -- /bin/tar cfz gnb-pcap.tgz pcap"
    kubectl -c tcpdump -n $NS exec -i $GNB_POD_NAME -- /bin/tar cfz gnb-pcap.tgz pcap || true
    echo "kubectl -c tcpdump cp $NS/$GNB_POD_NAME:gnb-pcap.tgz $prefix/gnb-pcap-"$DATE".tgz"
    kubectl -c tcpdump cp $NS/$GNB_POD_NAME:gnb-pcap.tgz $prefix/gnb-pcap-"$DATE".tgz || true
}

#################################################################################


function get-all-pcap(){
    prefix=$1; shift

    get-cn-pcap $prefix 
    get-ran-pcap $prefix
}


#################################################################################
#################################################################################
# Handle the different function calls 

if test $# -lt 1; then
    usage
else
    case $1 in
	init|start|stop|configure-all|start-cn|start-gnb|start-nr-ue|stop-cn|stop-gnb|stop-nr-ue|run-ping)
	    echo "$0: running $1"
	    "$1"
	;;
	*)
	    usage
    esac
fi

