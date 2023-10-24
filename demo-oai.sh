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
NODE_AMF_SPGWU="@DEF_NODE_AMF_SPGWU@" # node in wich run amf and spgwu pods
NODE_GNB="@DEF_NODE_GNB@" # node in which gnb pod runs
RRU="@DEF_RRU@" # in ['b210', 'n300', 'n320', 'jaguar', 'panther', 'rfsim']
GNB_ONLY="@DEF_GNB_ONLY@" # boolean, true if only RAN pods are launched
LOGS="@DEF_LOGS@" # boolean, true if logs are retrieved on pods
PCAP="@DEF_PCAP@" # boolean, true if pcap are generated on pods
#
MCC="@DEF_MCC@"
MNC="@DEF_MNC@"
DNN="@DEF_DNN@"
TAC="@DEF_TAC@"
SST0="@DEF_SST0@"
FULL_KEY="@DEF_FULL_KEY@"
OPC="@DEF_OPC@"
RFSIM_IMSI="@DEF_RFSIM_IMSI@"
#
PREFIX_DEMO="@DEF_PREFIX_DEMO@" # Directory in which all scripts will be copied on the k8s server to run the demo
#
#################################################################################
##################################################################################
PREFIX_STATS="/tmp/oai5g-stats"
OAISA_REPO="docker.io/oaisoftwarealliance"
P100="192.168.100"

# Interfaces names of VLANs in sopnode servers
IF_NAME_VLAN100="eth5"
#IF_NAME_VLAN100="p4-net"
IF_NAME_VLAN10="p4-net-10"
IF_NAME_VLAN20="p4-net-20"

############################### oai-cn5g chart parameters ########################
CN_TAG="v1.5.1"
#CN_TAG="develop"

OAI5G_CHARTS="$PREFIX_DEMO/oai-cn5g-fed/charts"
OAI5G_CORE="$OAI5G_CHARTS/oai-5g-core"
OAI5G_BASIC="$OAI5G_CORE/oai-5g-basic"

# Multus always used except in the case of B210 RRU
if [[ "$RRU" = "b210" ]]; then
    MULTUS_CREATE="false"
    IF_N2="eth0"
    IF_N3="eth0"
    IF_N4="eth0"
    IF_N6="eth0"
else
    MULTUS_CREATE="true"
    IF_N2="n2"
    IF_N3="n3"
    IF_N4="eth0" # should be "n4" but not still work to be done
    IF_N6="eth0" # should be "n6" but not still work to be done
fi

CN_DEFAULT_GW=""

#### mysql chart definitions ####
MYSQL_REPO="docker.io/mysql"
MYSQL_TAG="8.0" #previous 5.7 has issues on Rocky sopnode-w1 cluster with docker runtime

#### nrf-amf chart definitions ####
NRF_REPO="${OAISA_REPO}/oai-nrf"
NRF_TAG="${CN_TAG}"

#### oai-udr chart definitions ####
UDR_REPO="${OAISA_REPO}/oai-udr"
UDR_TAG="${CN_TAG}"

#### oai-udm chart definitions ####
UDM_REPO="${OAISA_REPO}/oai-udm"
UDM_TAG="${CN_TAG}"

#### nrf-ausf chart definitions ####
OAI5G_AUSF="$OAI5G_CORE/oai-ausf"
AUSF_REPO="${OAISA_REPO}/oai-ausf"
AUSF_TAG="${CN_TAG}"

#### oai-amf chart definitions ####
OAI5G_AMF="$OAI5G_CORE/oai-amf"
AMF_REPO="${OAISA_REPO}/oai-amf"
AMF_TAG="${CN_TAG}"
#
MULTUS_AMF_N2="$MULTUS_CREATE"
#IP_AMF_N2="$P100.241"
IP_AMF_N2="192.168.99.1"
NETMASK_AMF_N2="24"
GW_AMF_N2=""
ROUTES_AMF_N2=""
IF_NAME_AMF_N2="$IF_NAME_VLAN100" 

#### oai-spgwu-tiny chart definitions ####
OAI5G_SPGWU="$OAI5G_CORE/oai-spgwu-tiny"
SPGWU_REPO="docker.io/r2labuser/oai-spgwu-tiny"
SPGWU_TAG="rocky-test90"
#SPGWU_REPO="${OAISA_REPO}/oai-spgwu-tiny"
#SPGWU_TAG="${CN_TAG}"
#
MULTUS_SPGWU_N3="$MULTUS_CREATE"
#IP_SPGWU_N3="$P100.242" 
IP_SPGWU_N3="192.168.99.2" 
NETMASK_SPGWU_N3="24"
GW_SPGWU_N3=""
ROUTES_SPGWU_N3=""
IF_NAME_SPGWU_N3="$IF_NAME_VLAN100"
#
MULTUS_SPGWU_N4="false"
IP_SPGWU_N4="" 
NETMASK_SPGWU_N4=""
GW_SPGWU_N4=""
ROUTES_SPGWU_N4=""
IF_NAME_SPGWU_N4=""
#
MULTUS_SPGWU_N6="false"
IP_SPGWU_N6="" 
NETMASK_SPGWU_N6=""
GW_SPGWU_N6=""
ROUTES_SPGWU_N6=""
IF_NAME_SPGWU_N6="" 

#### oai-smf chart definitions ####
OAI5G_SMF="$OAI5G_CORE/oai-smf"
SMF_REPO="${OAISA_REPO}/oai-smf"
SMF_TAG="${CN_TAG}"
MULTUS_SMF_N4="false"
IP_SMF_N4="" 
NETMASK_SMF_N4=""
GW_SMF_N4=""
ROUTES_SMF_N4=""
IF_NAME_SMF_N4="" 
IP_DNS1="138.96.0.210"
IP_DNS2="193.51.196.138"
IP_CSCF="127.0.0.1" # unused but without seting an IP, the SMF pod crashes!

################################ oai-gnb chart parameters ########################
OAI5G_RAN="$OAI5G_CHARTS/oai-5g-ran"
#
RAN_TAG="2023.w37"
#RAN_TAG="2023.w19"
GNB_NAME="gNB-r2lab"
#IP_GNB_N2N3="$P100.243"
IP_GNB_N2N3="192.168.99.3"
IF_NAME_GNB_N2="$IF_NAME_VLAN100"
IF_NAME_GNB_N3="" # unused for current scenario with same PHY network interface for N2/N3
NETMASK_GNB_N2="24"
NETMASK_GNB_N3=""
NETMASK_GNB_RU="24"

#### RFSIM RU case ####
GNB_RFSIM_REPO="${OAISA_REPO}/oai-gnb"
GNB_RFSIM_TAG="${RAN_TAG}"
#GNB_RFSIM_TAG="2023.w12"
CONF_RFSIM="gnb.sa.band78.106prb.rfsim.2x2.conf" 
OPTIONS_RFSIM="--sa -E --rfsim --log_config.global_log_options level,nocolor,time"

#### B210 RU case ####
## for up4000 ubuntu20
#GNB_B210_REPO="docker.io/r2labuser/oai-gnb"
GNB_B210_REPO="${OAISA_REPO}/oai-gnb"
GNB_B210_TAG="2023.w37"
#GNB_B210_TAG="${RAN_TAG}"
#GNB_B210_TAG="2023.w11b"
#CONF_B210="gnb.sa.band78.51prb.usrpb200.conf"
CONF_B210="gnb.sa.band78.fr1.51PRB.usrpb210-new.conf"
#OPTIONS_B210="--sa  --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"
OPTIONS_B210="--sa -E --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"

#### N3XX RU case ####
GNB_N3XX_REPO="${OAISA_REPO}/oai-gnb"
#GNB_N3XX_REPO="docker.io/r2labuser/oai-gnb"
GNB_N3XX_TAG="${RAN_TAG}"
#GNB_N3XX_TAG="bugfix-phy-mac-interface"
CONF_N3XX="gnb.sa.band78.106prb.usrpn310.ddsuu-2x2.conf"
#CONF_N3XX="gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf"
OPTIONS_N3XX="--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 0,2,4,6,8,10,12,14,16 --log_config.global_log_options level,nocolor,time"
IP_GNB_SFP1="192.168.10.132"
IP_GNB_SFP2="192.168.20.132"
MTU_N3XX="9000"
IF_NAME_N3XX_1="$IF_NAME_VLAN10"
IF_NAME_N3XX_2="$IF_NAME_VLAN20"
ADDRS_N300="addr=192.168.10.129,second_addr=192.168.20.129"
ADDRS_N320="addr=192.168.10.130,second_addr=192.168.20.130"

#### AW2S RU case ####
GNB_AW2S_REPO="docker.io/r2labuser/oai-gnb-aw2s"
GNB_AW2S_TAG="rocky.2023.w37"
#GNB_AW2S_TAG="${RAN_TAG}"
#GNB_AW2S_TAG="rocky"
CONF_JAGUAR="gnb.sa.band78.51prb.aw2s.ddsuu.conf"
#CONF_JAGUAR="oai-gNB-n78_50M_DDDSU.conf"
CONF_PANTHER="gnb.sa.band78.51prb.aw2s.ddsuu.conf"
#CONF_PANTHER="oai-gNB-n78_50M_DDDSU.conf"
OPTIONS_AW2S="--sa --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"
IP_GNB_AW2S="$P100.243" 
IF_NAME_GNB_AW2S="$IF_NAME_VLAN100"
ADDR_JAGUAR="$P100.48" 
ADDR_PANTHER="$P100.51"


########################### oai-nr-ue rfsim chart parameters #####################
OAI5G_NRUE="$OAI5G_CORE/oai-nr-ue"
NRUE_REPO="${OAISA_REPO}/oai-nr-ue"
NRUE_TAG="${RAN_TAG}"
OPTIONS_NRUE="--sa -E --rfsim -r 106 --numerology 1 -C 3319680000 --nokrnmod --log_config.global_log_options level,nocolor,time"
IP_NRUE="192.168.99.4"
NETMASK_NRUE="24"
IF_NAME_NRUE="$IF_NAME_VLAN100"

###################### Scenario with External Core Network #######################


# If an external Core Network is used (i.e., GNB_ONLY is "true")
# then, configure the following parameters
if [[ $GNB_ONLY = "true" ]]; then
    # Set the external AMF IP address
    AMF_IP_ADDR="172.22.10.6" # external AMF IP address, e.g., "172.22.10.6"
    # Set the local host network interface to reach AMF/UPF
    IF_NAME_GNB_N2="ran" # Host network interface to reach AMF/UPF
    # Set the local IP address of the latter network interface
    IP_GNB_N2N3="10.0.20.243" # local gNB IP required by AMF/UPF, e.g., "10.0.20.243"
    # Set the route to reach AMF/UPF
    ROUTES_GNB_N2="[{'dst': '172.22.10.0/24','gw': '10.0.20.1'}]"
fi

##################################################################################

# Generate unique MAC addresses for multus interfaces in oai5g pods
function gener-mac()
{
    CPTfile="/tmp/cpt-$$.dat"
    PREFIXfile="/tmp/prefix-$$.dat"
    if [ ! -f "$CPTfile" ]; then
	CPT=0
    else
	CPT=$(cat "$CPTfile")
    fi
    if [ ! -f "$PREFIXfile" ]; then
	PREFIX="12:34:"
	case $IF_NAME_VLAN100 in
	    "eth5")
		PREFIX=$PREFIX"00:";;
	    "p4-net")
		PREFIX=$PREFIX"01:";;
	    *)  PREFIX=$PREFIX"02:";;
	esac
	case $NODE_AMF_SGPWU in
	    "sopnode-l1.inria.fr")
		PREFIX=$PREFIX"00:";;
	    "sopnode-w1.inria.fr")
		PREFIX=$PREFIX"01:";;
	    *)  PREFIX=$PREFIX"02:";;
	esac
	case $NODE_GNB in
	    "sopnode-l1.inria.fr")
		PREFIX=$PREFIX"00:";;	
	    "sopnode-w1.inria.fr")
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
    # Following is no more useful as it is already done through the ansible playbook
    ## Ensure that helm spray plugin is installed
    #echo "init: ensure spray is installed and possibly create secret docker-registry"
    #helm plugin uninstall helm-spray || true
    #helm plugin install https://github.com/ThalesGroup/helm-spray || true
    ## Just in case the k8s cluster has been restarted without multus enabled..
    #echo "kube-install.sh enable-multus"
    #kube-install.sh enable-multus || true

}

#################################################################################

function configure-oai-5g-basic() {

    # if $LOGS is true, create a tcpdump container with privileges
    # if $PCAP is true, start tcpdump and create a shared volume to store pcap
    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/basic-r2lab.sed <<EOF
s|@PRIVILEGED@|$LOGS|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@START_TCPDUMP@|$PCAP|
s|@SHAREDVOLUME@|$PCAP|
s|@CN_DEFAULT_GW@|$CN_DEFAULT_GW|
s|@NSSAI_SST0@|$SST0|
s|@NSSAI_SD0@|0xFFFFFF|
s|@DNN0@|$DNN|
s|@MYSQL_REPO@|$MYSQL_REPO|
s|@MYSQL_TAG@|$MYSQL_TAG|
s|@NRF_REPO@|${NRF_REPO}|
s|@NRF_TAG@|${NRF_TAG}|
s|@UDR_REPO@|${UDR_REPO}|
s|@UDR_TAG@|${UDR_TAG}|
s|@UDM_REPO@|${UDM_REPO}|
s|@UDM_TAG@|${UDM_TAG}|
s|@AUSF_REPO@|${AUSF_REPO}|
s|@AUSF_TAG@|${AUSF_TAG}|
s|@AMF_REPO@|${AMF_REPO}|
s|@AMF_TAG@|${AMF_TAG}|
s|@MULTUS_AMF_N2@|$MULTUS_AMF_N2|
s|@IP_AMF_N2@|$IP_AMF_N2|
s|@NETMASK_AMF_N2@|$NETMASK_AMF_N2|
s|@MAC_AMF_N2@|$(gener-mac)|
s|@GW_AMF_N2@|$GW_AMF_N2|
s|@ROUTES_AMF_N2@|$ROUTES_AMF_N2|
s|@IF_NAME_AMF_N2@|$IF_NAME_AMF_N2|
s|@IF_N2@|$IF_N2|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@TAC@|0x0001|
s|@NODE_AMF@|"$NODE_AMF_SPGWU"|
s|@SPGWU_REPO@|${SPGWU_REPO}|
s|@SPGWU_TAG@|${SPGWU_TAG}|
s|@MULTUS_SPGWU_N3@|$MULTUS_SPGWU_N3|
s|@IP_SPGWU_N3@|$IP_SPGWU_N3|
s|@NETMASK_SPGWU_N3@|$NETMASK_SPGWU_N3|
s|@MAC_SPGWU_N3@|$(gener-mac)|
s|@GW_SPGWU_N3@|$GW_SPGWU_N3|
s|@ROUTES_SPGWU_N3@|$ROUTES_SPGWU_N3|
s|@IF_NAME_SPGWU_N3@|$IF_NAME_SPGWU_N3|
s|@MULTUS_SPGWU_N4@|$MULTUS_SPGWU_N4|
s|@IP_SPGWU_N4@|$IP_SPGWU_N4|
s|@NETMASK_SPGWU_N4@|$NETMASK_SPGWU_N4|
s|@MAC_SPGWU_N4@|$(gener-mac)|
s|@GW_SPGWU_N4@|$GW_SPGWU_N4|
s|@ROUTES_SPGWU_N4@|$ROUTES_SPGWU_N4|
s|@IF_NAME_SPGWU_N4@|$IF_NAME_SPGWU_N4|
s|@MULTUS_SPGWU_N6@|$MULTUS_SPGWU_N6|
s|@IP_SPGWU_N6@|$IP_SPGWU_N6|
s|@NETMASK_SPGWU_N6@|$NETMASK_SPGWU_N6|
s|@MAC_SPGWU_N6@|$(gener-mac)|
s|@GW_SPGWU_N6@|$GW_SPGWU_N6|
s|@ROUTES_SPGWU_N6@|$ROUTES_SPGWU_N6|
s|@IF_NAME_SPGWU_N6@|$IF_NAME_SPGWU_N6|
s|@IF_N3@|$IF_N3|
s|@IF_N4@|$IF_N4|
s|@IF_N6@|$IF_N6|
s|@NODE_SPGWU@|"$NODE_AMF_SPGWU"|
s|@SMF_REPO@|${SMF_REPO}|
s|@SMF_TAG@|${SMF_TAG}|
s|@MULTUS_SMF_N4@|$MULTUS_SMF_N4|
s|@IP_SMF_N4@|$IP_SMF_N4|
s|@NETMASK_SMF_N4@|$NETMASK_SMF_N4|
s|@MAC_SMF_N4@|$(gener-mac)|
s|@GW_SMF_N4@|$GW_SMF_N4|
s|@ROUTES_SMF_N4@|$ROUTES_SMF_N4|
s|@IF_NAME_SMF_N4@|$IF_NAME_SMF_N4|
s|@IP_DNS1@|$IP_DNS1|
s|@IP_DNS2@|$IP_DNS2|
s|@IP_CSCF@|$IP_CSCF|
s|@NODE_SMF@||
EOF
    cp "$OAI5G_BASIC"/values.yaml /tmp/basic_values.yaml-orig
    echo "(Over)writing $OAI5G_BASIC/values.yaml"
    sed -f /tmp/basic-r2lab.sed < /tmp/basic_values.yaml-orig > "$OAI5G_BASIC"/values.yaml
    diff /tmp/basic_values.yaml-orig "$OAI5G_BASIC"/values.yaml
        
    cd "$OAI5G_BASIC"
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
    DIR_GNB_DEST="$PREFIX_DEMO/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb"
    DIR_TEMPLATES="$DIR_GNB_DEST/templates"

    SED_CONF_FILE="/tmp/gnb_conf.sed"
    SED_VALUES_FILE="/tmp/oai-gnb-values.sed"
    SED_DEPLOYMENT_FILE="/tmp/oai-gnb-deployment.sed"

    # Configure parameters for values.yaml chart according to RRU type
    if [[ "$RRU" = "b210" ]]; then
	# no multus as FIT nodes not connected to VLAN100
	# AMF/NGA/NGU IP addresses will be set just before the gnb pod starts
	CONF_ORIG="$DIR_CONF/$CONF_B210"
	GNB_REPO="$GNB_B210_REPO"
	GNB_TAG="$GNB_B210_TAG"
	GNB_NAME="$GNB_NAME-b210"
	if [[ "$GNB_ONLY" = "true" ]]; then
	    MULTUS_GNB_N2="true"
	    GNB_NGA_IF_NAME="$IF_NAME_GNB_N2"
	    GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3"
	    GNB_NGU_IF_NAME="$IF_NAME_GNB_N2"
	    GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3"
	else
	    MULTUS_GNB_N2="false"
	    GNB_NGA_IF_NAME="eth0"
	    GNB_NGU_IF_NAME="eth0"
	fi
	MULTUS_GNB_N3="false"
	MULTUS_GNB_RU1="false"
	MULTUS_GNB_RU2="false"
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="b210"
	ADD_OPTIONS_GNB="$OPTIONS_B210"
	QOS_GNB_DEF="false"

    elif [[ "$RRU" = "n300" || "$RRU" = "n320" ]]; then
	if [[ "$RRU" = "n300" ]]; then
	    GNB_NAME="$GNB_NAME-n300"
	    SDR_ADDRS="$ADDRS_N300"
	elif [[ "$RRU" = "n320" ]]; then
	    GNB_NAME="$GNB_NAME-n320"
	    SDR_ADDRS="$ADDRS_N320"
	fi
	CONF_ORIG="$DIR_CONF/$CONF_N3XX"
	GNB_REPO="$GNB_N3XX_REPO"
	GNB_TAG="$GNB_N3XX_TAG"
	MULTUS_GNB_N2="true"
	GNB_NGA_IF_NAME="n2"
	GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_NGU_IF_NAME="n2"
	GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3/24"
	MULTUS_GNB_RU1="true"
	IP_GNB_RU1="$IP_GNB_SFP1"
	MTU_GNB_RU1="$MTU_N3XX"
	IF_NAME_GNB_RU1="$IF_NAME_N3XX_1"
	MULTUS_GNB_RU2="true"
	IP_GNB_RU2="$IP_GNB_SFP2"
	MTU_GNB_RU2="$MTU_N3XX"
	IF_NAME_GNB_RU2="$IF_NAME_N3XX_2"
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="n3xx"
	ADD_OPTIONS_GNB="$OPTIONS_N3XX"
	QOS_GNB_DEF="true"

    elif [[ "$RRU" = "jaguar" || "$RRU" = "panther" ]]; then
	if [[ "$RRU" = "jaguar" ]]; then
	    GNB_NAME="$GNB_NAME-jaguar"
	    CONF_AW2S="$CONF_JAGUAR"
	    ADDR_AW2S="$ADDR_JAGUAR"
	else
	    GNB_NAME="$GNB_NAME-panther"
	    CONF_AW2S="$CONF_PANTHER"
	    ADDR_AW2S="$ADDR_PANTHER"
	fi
	CONF_ORIG="$DIR_CONF/$CONF_AW2S"
	GNB_REPO="$GNB_AW2S_REPO"
	GNB_TAG="$GNB_AW2S_TAG"
	MULTUS_GNB_N2="true"
	GNB_NGA_IF_NAME="n2"
	GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_NGU_IF_NAME="n2"
	GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_AW2S_LOCAL_IF_NAME="ru1"
	MULTUS_GNB_N3="false"
	MULTUS_GNB_RU1="true"
	IP_GNB_RU1="$IP_GNB_AW2S"
	IF_NAME_GNB_RU1="$IF_NAME_GNB_AW2S"
	MULTUS_GNB_RU2="false"
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="aw2s"
	ADD_OPTIONS_GNB="$OPTIONS_AW2S"
	QOS_GNB_DEF="true"
	
    elif [[ "$RRU" = "rfsim" ]]; then
	CONF_ORIG="$DIR_CONF/$CONF_RFSIM"
        GNB_NAME="$GNB_NAME-rfsim"
	GNB_REPO="$GNB_RFSIM_REPO"
	GNB_TAG="$GNB_RFSIM_TAG"
	MULTUS_GNB_N2="true"
	GNB_NGA_IF_NAME="n2"
	GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_NGU_IF_NAME="n2"
	GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3/24"
	MULTUS_GNB_N3="false"
	MULTUS_GNB_RU1="false"
	MULTUS_GNB_RU2="false"
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="rfsim"
	ADD_OPTIONS_GNB="$OPTIONS_RFSIM"
	QOS_GNB_DEF="false"

    else
	echo "Unknown rru selected: $RRU"
	usage
    fi
    
    if [[ "$MOUNTCONFIG_GNB" = "true" ]]; then
	echo "Insert gNB conf file $CONF_ORIG in configmap.yaml"
	# Keep the 17 first lines of configmap.yaml
	head -17  "$DIR_TEMPLATES"/configmap.yaml > /tmp/configmap.yaml
	# Add a 6-characters margin to gnb.conf
	awk '$0="      "$0' "$CONF_ORIG" > /tmp/gnb.conf
	# Append the modified gnb.conf to /tmp/configmap.yaml
	cat /tmp/gnb.conf >> /tmp/configmap.yaml
	echo -e "\n{{- end }}\n" >> /tmp/configmap.yaml
	mv /tmp/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml

	echo "First configure gnb.conf within configmap.yaml"
	# remove NSSAI sd info for PLMN and add other parameters for RUs
	# in the case of b210 (without multus), AMF_IP_ADDR will be set again just before running the gNB
	cat > "$SED_CONF_FILE" <<EOF
s|@GNB_NAME@|$GNB_NAME|
s|@TAC@|$TAC|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@SST@|$SST0|
s|@AMF_IP_ADDRESS@|$IP_AMF_N2|
s|@GNB_NGA_IF_NAME@|$GNB_NGA_IF_NAME|
s|@GNB_NGA_IP_ADDRESS@|$GNB_NGA_IP_ADDRESS|
s|@GNB_NGU_IF_NAME@|$GNB_NGU_IF_NAME|
s|@GNB_NGU_IP_ADDRESS@|$GNB_NGU_IP_ADDRESS|
s|@AW2S_IP_ADDRESS@|$ADDR_AW2S|
s|@GNB_AW2S_IP_ADDRESS@|$IP_GNB_AW2S|
s|@GNB_AW2S_LOCAL_IF_NAME@|$GNB_AW2S_LOCAL_IF_NAME|
s|@SDR_ADDRS@|$SDR_ADDRS,clock_source=internal,time_source=internal|
EOF
	cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
	sed -f "$SED_CONF_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
	echo "Display new $DIR_TEMPLATES/configmap.yaml"
	cat "$DIR_TEMPLATES"/configmap.yaml
    fi

    # Configure gnb values.yaml chart
    DIR="$OAI5G_RAN/oai-gnb"

    echo "Then configure oai-gnb charts"
    cat > "$SED_VALUES_FILE" <<EOF
s|@GNB_REPO@|$GNB_REPO|
s|@GNB_TAG@|$GNB_TAG|
s|@DEFAULT_GW_GNB@|$DEFAULT_GW_GNB|
s|@MULTUS_GNB_N2@|$MULTUS_GNB_N2|
s|@IP_GNB_N2@|$IP_GNB_N2N3|
s|@NETMASK_GNB_N2@|$NETMASK_GNB_N2|
s|@MAC_GNB_N2@|$(gener-mac)|
s|@GW_GNB_N2@|$GW_GNB_N2|
s|@ROUTES_GNB_N2@|$ROUTES_GNB_N2|
s|@IF_NAME_GNB_N2@|$IF_NAME_GNB_N2|
s|@MULTUS_GNB_N3@|$MULTUS_GNB_N3|
s|@IP_GNB_N3@|$IP_GNB_N3|
s|@NETMASK_GNB_N3@|$NETMASK_GNB_N3|
s|@MAC_GNB_N3@|$(gener-mac)|
s|@GW_GNB_N3@|$GW_GNB_N3|
s|@ROUTES_GNB_N3@|$ROUTES_GNB_N3|
s|@IF_NAME_GNB_N3@|$IF_NAME_GNB_N3|
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
s|@MOUNTCONFIG_GNB@|$MOUNTCONFIG_GNB|
s|@RRU_TYPE@|$RRU_TYPE|
s|@ADD_OPTIONS_GNB@|$ADD_OPTIONS_GNB|
s|@AMF_IP_ADDRESS@|$IP_AMF_N2|
s|@GNB_NAME@|$GNB_NAME|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@TAC@|$TAC|
s|@SST@|$SST0|
s|@GNB_NGA_IF_NAME@|$GNB_NGA_IF_NAME|
s|@IP_GNB_N2N3@|$IP_GNB_N2N3|
s|@GNB_NGU_IF_NAME@|$GNB_NGU_IF_NAME|
s|@PCAP@|$PCAP|
s|@START_TCPDUMP@|$PCAP|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@SHAREDVOLUME@|$PCAP|
s|@QOS_GNB_DEF@|$QOS_GNB_DEF|
s|@NODE_GNB@|$NODE_GNB|
EOF
    ORIG_CHART="$DIR"/values.yaml
    cp "$ORIG_CHART" /tmp/oai-gnb_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_VALUES_FILE" < /tmp/oai-gnb_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/oai-gnb_values.yaml-orig "$ORIG_CHART" 
}

#################################################################################

function configure-nr-ue() {

    # will NOT generate PCAP file to avoid wasting all memory resources
    # However, a tcpdump container created e.g., to run iperf client"
    DIR="$OAI5G_RAN/oai-nr-ue"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="/tmp/oai-nr-ue-values.sed"
    echo "configure-nr-ue: $ORIG_CHART configuration"
    ADD_OPTIONS_NRUE="$OPTIONS_NRUE"
    SSD="16777215"
    cat > "$SED_FILE" <<EOF
s|@NRUE_REPO@|$NRUE_REPO|
s|@NRUE_TAG@|$NRUE_TAG|
s|@MULTUS_NRUE@|true|
s|@IP_NRUE@|$IP_NRUE|
s|@NETMASK_NRUE@|$NETMASK_NRUE|
s|@MAC_NRUE@|$(gener-mac)|
s|@DEFAULT_GW_NRUE@|$DEFAULT_GW_NRUE|
s|@IF_NAME_NRUE@|$IF_NAME_NRUE|
s|@IP_GNB@|$IP_GNB_N2N3|
s|@RFSIM_IMSI@|$RFSIM_IMSI|
s|@FULL_KEY@|$FULL_KEY|
s|@OPC@|$OPC|
s|@DNN@|$DNN|
s|@SST@|$SST0|
s|@SSD@|$SSD|
s|@ADD_OPTIONS_NRUE@|$ADD_OPTIONS_NRUE|
s|@START_TCPDUMP@|false|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@QOS_NRUE_DEF@|false|
s|@SHAREDVOLUME@|false|
s|@NODE_NRUE@||
EOF
    cp "$ORIG_CHART" /tmp/oai-nr-ue_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < /tmp/oai-nr-ue_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/oai-nr-ue_values.yaml-orig "$ORIG_CHART"
}


#################################################################################

function configure-all() {
    echo "configure-all: Applying SophiaNode patches to OAI5G charts located on "$PREFIX_DEMO"/oai-cn5g-fed"
    echo -e "\t with oai-spgwu-tiny running on $NODE_AMF_SPGWU"
    echo -e "\t with oai-gnb running on $NODE_GNB"
    echo -e "\t with generate-logs: $LOGS"
    echo -e "\t with generate-pcap: $PCAP"

    # Remove pulling limitations from docker-hub with anonymous account
    echo "Create $NS if not present and regcred secret"	     
    kubectl create namespace $NS || true
    kubectl -n $NS delete secret regcred || true
    kubectl -n $NS create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=@DEF_REGCRED_NAME@ --docker-password=@DEF_REGCRED_PWD@ --docker-email=@DEF_REGCRED_EMAIL@ || true

    # Ensure that helm spray plugin is installed
    configure-oai-5g-basic 
    configure-mysql
    configure-gnb
    if [[ "$RRU" = "rfsim" ]]; then
	configure-nr-ue
    fi
}

#################################################################################


function start-cn() {
    ns=$1
    shift
    node_amf_spgwu=$1
    shift

    echo "Running start-cn() with namespace=$NS, NODE_AMF_SPGWU=$NODE_AMF_SPGWU"

    echo "cd $OAI5G_BASIC"
    cd "$OAI5G_BASIC"

    echo "helm dependency update"
    helm dependency update

    echo "helm --namespace=$NS spray ."
    helm --create-namespace --namespace=$NS spray .

    echo "Wait until all 5G Core pods are READY"
    kubectl wait pod -n $NS --for=condition=Ready --all
}

#################################################################################


function start-gnb() {
    echo "Running start-gnb() with namespace=$NS, NODE_GNB=$NODE_GNB and rru=$RRU"

    DIR="$OAI5G_RAN/oai-gnb"
    DIR_TEMPLATES="$DIR/templates"
    if [[ "$RRU" = "b210" ]]; then
	echo "Set AMF IP address in gnb conf"
	if [[ $GNB_ONLY = "true" ]]; then
	    AMF_IP="$AMF_IP_ADDR" # external CN including AMF
	else
	    AMF_POD_NAME=$(kubectl -n $NS get pods -l app.kubernetes.io/name=oai-amf -o jsonpath="{.items[0].metadata.name}")
	    AMF_IP=$(kubectl -n $NS get pod $AMF_POD_NAME --template '{{.status.podIP}}')
	fi
	SED_FILE="/tmp/gnb-configmap.sed"
	cat > "$SED_FILE" <<EOF
s|ipv4       =.*|ipv4       = "$AMF_IP";|
EOF
	cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
	sed -f "$SED_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
	echo "set AMF IP address in chart $DIR_TEMPLATES/configmap.yaml"
	diff /tmp/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml
	SED_FILE="/tmp/gnb-values.sed"
	cat > "$SED_FILE" <<EOF
s|amfIpAddress:.*|amfIpAddress: "$AMF_IP"|
EOF
	cp "$DIR"/values.yaml /tmp/values.yaml
	sed -f "$SED_FILE" < /tmp/values.yaml > "$DIR"/values.yaml
	echo "set AMF IP address in chart $DIR/values.yaml"
	diff /tmp/values.yaml "$DIR"/values.yaml
    else
	AMF_IP="$IP_AMF_N2"
    fi

    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="/tmp/oai-gnb_values.sed"
    echo "Setting AMF IP address (for tcpdump filter) in chart $ORIG_CHART"
    cat > $SED_FILE <<EOF
s|@AMF_IP_ADDRESS@|$AMF_IP|
EOF
    cp "$ORIG_CHART" /tmp/oai-gnb_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < /tmp/oai-gnb_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/oai-gnb_values.yaml-orig "$ORIG_CHART"
    
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    echo "helm -n $NS install oai-gnb oai-gnb/"
    helm -n $NS install oai-gnb oai-gnb/

    echo "Wait until the gNB pod is READY"
    echo "kubectl -n $NS wait pod --for=condition=Ready --all"
    kubectl -n $NS wait pod --for=condition=Ready --all
}

#################################################################################

function start-nr-ue() {
    ns=$1
    shift
    node_gnb=$1
    shift

    echo "Running start-nr-ue() on namespace: $NS, NODE_GNB=$NODE_GNB"
    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

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
	cat << \EOF >> /tmp/oai5g-pv.yaml
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
	kubectl apply -f /tmp/oai5g-pv.yaml

	echo "start: Create a k8s persistence volume for generation of CN logs files"
	cat << \EOF >> /tmp/cn5g-pv.yaml
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
	kubectl apply -f /tmp/cn5g-pv.yaml

	
	echo "start: Create a k8s persistent volume claim for RAN logs files"
    cat << \EOF >> /tmp/oai5g-pvc.yaml
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
    echo "kubectl -n $NS apply -f /tmp/oai5g-pvc.yaml"
    kubectl -n $NS apply -f /tmp/oai5g-pvc.yaml

	echo "start: Create a k8s persistent volume claim for CN logs files"
    cat << \EOF >> /tmp/cn5g-pvc.yaml
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
    echo "kubectl -n $NS apply -f /tmp/cn5g-pvc.yaml"
    kubectl -n $NS apply -f /tmp/cn5g-pvc.yaml
    fi

    if [[ "$GNB_ONLY" = "false" ]]; then
	start-cn 
    fi
    start-gnb 

    if [[ "$RRU" = "rfsim" ]]; then
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
    echo "helm -n $NS uninstall oai-spgwu-tiny oai-nrf oai-udr oai-udm oai-ausf oai-smf oai-amf mysql"
    helm -n $NS uninstall oai-smf
    helm -n $NS uninstall oai-spgwu-tiny
    helm -n $NS uninstall oai-amf
    helm -n $NS uninstall oai-ausf
    helm -n $NS uninstall oai-udm
    helm -n $NS uninstall oai-udr
    helm -n $NS uninstall oai-nrf
    helm -n $NS uninstall mysql
}


function stop-gnb(){
    echo "helm -n $NS uninstall oai-gnb"
    helm -n $NS uninstall oai-gnb
}


function stop-nr-ue(){
    echo "helm -n $NS uninstall oai-nr-ue"
    helm -n $NS uninstall oai-nr-ue
}


function stop() {
    echo "Running stop() on $NS namespace, logs=$LOGS"

    if [[ "$LOGS" = "true" ]]; then
	dir_stats=${PREFIX_STATS-"/tmp/oai5g-stats"}
	echo "First retrieve all pcap and logs files in $dir_stats and compressed it"
	mkdir -p $dir_stats
	echo "cleanup $dir_stats before including new logs/pcap files"
	cd $dir_stats; rm -f *.pcap *.tgz *.logs *stats* *.conf
	if [[ "$PCAP" = "true" ]]; then
	    get-all-pcap $dir_stats
	fi
	get-all-logs $dir_stats
	cd /tmp; dirname=$(basename $dir_stats)
	echo tar cfz "$dirname".tgz $dirname
	tar cfz "$dirname".tgz $dirname
    fi

    res=$(helm -n $NS ls | wc -l)
    if test $res -gt 1; then
        echo "Remove all 5G OAI pods"
	if [[ "$GNB_ONLY" = "false" ]]; then
	    stop-cn
	fi
	stop-gnb
	if [[ "$RRU" = "rfsim" ]]; then
	    stop-nr-ue
	fi
    else
        echo "OAI5G demo is not running, there is no pod on namespace $NS !"
    fi

    echo "Wait until all $NS pods disppear"
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

AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[0].metadata.name}")
AMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-amf $AMF_POD_NAME running with IP $AMF_eth0_IP"
kubectl --namespace $NS -c amf logs $AMF_POD_NAME > "$prefix"/amf-"$DATE".logs

AUSF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-ausf" -o jsonpath="{.items[0].metadata.name}")
AUSF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-ausf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-ausf $AUSF_POD_NAME running with IP $AUSF_eth0_IP"
kubectl --namespace $NS -c ausf logs $AUSF_POD_NAME > "$prefix"/ausf-"$DATE".logs

GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
GNB_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-gnb $GNB_POD_NAME running with IP $GNB_eth0_IP"
kubectl --namespace $NS -c gnb logs $GNB_POD_NAME > "$prefix"/gnb-"$DATE".logs

NRF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-nrf" -o jsonpath="{.items[0].metadata.name}")
NRF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-nrf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-nrf $NRF_POD_NAME running with IP $NRF_eth0_IP"
kubectl --namespace $NS -c nrf logs $NRF_POD_NAME > "$prefix"/nrf-"$DATE".logs

SMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-smf" -o jsonpath="{.items[0].metadata.name}")
SMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-smf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-smf $SMF_POD_NAME running with IP $SMF_eth0_IP"
kubectl --namespace $NS -c smf logs $SMF_POD_NAME > "$prefix"/smf-"$DATE".logs

SPGWU_TINY_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-spgwu-tiny,app.kubernetes.io/instance=oai-spgwu-tiny" -o jsonpath="{.items[0].metadata.name}")
SPGWU_TINY_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-spgwu-tiny,app.kubernetes.io/instance=oai-spgwu-tiny" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-spgwu-tiny $SPGWU_TINY_POD_NAME running with IP $SPGWU_TINY_eth0_IP"
kubectl --namespace $NS -c spgwu logs $SPGWU_TINY_POD_NAME > "$prefix"/spgwu-tiny-"$DATE".logs

UDM_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-udm" -o jsonpath="{.items[0].metadata.name}")
UDM_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-udm" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-udm $UDM_POD_NAME running with IP $UDM_eth0_IP"
kubectl --namespace $NS -c udm logs $UDM_POD_NAME > "$prefix"/udm-"$DATE".logs

UDR_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-udr" -o jsonpath="{.items[0].metadata.name}")
UDR_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-udr" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-udr $UDR_POD_NAME running with IP $UDR_eth0_IP"
kubectl --namespace $NS -c udr logs $UDR_POD_NAME > "$prefix"/udr-"$DATE".logs

if [[ "$RRU" = "rfsim" ]]; then
NRUE_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
NRUE_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-nr-ue $NRUE_POD_NAME running with IP $NRUE_eth0_IP"
kubectl --namespace $NS -c nr-ue logs $NRUE_POD_NAME > "$prefix"/nr-ue-"$DATE".logs
fi

echo "Retrieve gnb config from the pod"
if [[ "$RRU" = "jaguar" || "$RRU" = "panther" ]]; then
    kubectl -c gnb cp $NS/$GNB_POD_NAME:/opt/oai-gnb-aw2s/etc/gnb.conf $prefix/gnb.conf || true
else
    kubectl -c gnb cp $NS/$GNB_POD_NAME:/opt/oai-gnb/etc/gnb.conf $prefix/gnb.conf || true
fi

echo "Retrieve nrL1_stats.log, nrMAC_stats.log and nrRRC_stats.log from gnb pod"
kubectl -c gnb cp $NS/$GNB_POD_NAME:nrL1_stats.log $prefix/nrL1_stats.log"$DATE" || true
kubectl -c gnb cp $NS/$GNB_POD_NAME:nrMAC_stats.log $prefix/nrMAC_stats.log"$DATE" || true
kubectl -c gnb cp $NS/$GNB_POD_NAME:nrRRC_stats.log $prefix/nrRRC_stats.log"$DATE" || true
}

#################################################################################

function get-cn-pcap(){
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[0].metadata.name}")
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
# No more pcap for UE now
#    if [[ "$RRU" = "rfsim" ]]; then
#	NRUE_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
#	echo "Retrieve OAI5G pcap file from the oai-nr-ue pod on ns $NS"
#	echo "kubectl -c tcpdump -n $NS exec -i $NRUE_POD_NAME -- /bin/tar cfz nr-ue-pcap.tgz pcap"
#	kubectl -c tcpdump -n $NS exec -i $NRUE_POD_NAME -- /bin/tar cfz nr-ue-pcap.tgz pcap || true
#	echo "kubectl -c tcpdump cp $NS/$NRUE_POD_NAME:nr-ue-pcap.tgz $prefix/nr-ue-pcap-"$DATE".tgz"
#	kubectl -c tcpdump cp $NS/$NRUE_POD_NAME:nr-ue-pcap.tgz $prefix/nr-ue-pcap-"$DATE".tgz || true
#    fi
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

