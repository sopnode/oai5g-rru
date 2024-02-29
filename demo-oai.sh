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
GNB_ONLY="@DEF_GNB_ONLY@" # boolean, true if only RAN pods are launched
LOGS="@DEF_LOGS@" # boolean, true if logs are retrieved on pods
PCAP="@DEF_PCAP@" # boolean, true if pcap are generated on pods
#
MCC="@DEF_MCC@"
MNC="@DEF_MNC@"
DNN="@DEF_DNN@"
TAC="@DEF_TAC@"
################SST0="@DEF_SST0@"
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
P99="192.168.99"
P100="192.168.100"
SUBNET_N2N3="$P99"
IF_NAME_N2N3="net-100"
#IF_NAME_N2N3="eth4"

# Interfaces names of VLANs in sopnode servers
IF_NAME_VLAN100="net-100"
IF_NAME_VLAN10="net-10"
IF_NAME_VLAN20="net-20"

############################### oai-cn5g chart parameters ########################
#CN_TAG="v1.5.1"
#CN_TAG="develop"

OAI5G_CHARTS="$PREFIX_DEMO/oai-cn5g-fed/charts"
OAI5G_CORE="$OAI5G_CHARTS/oai-5g-core"
OAI5G_BASIC="$OAI5G_CORE/oai-5g-basic"
OAI5G_ADVANCE="$OAI5G_CORE/oai-5g-advance"

# Multus is now used whatever RRU selected
MULTUS_CREATE="true"
IF_N2="n2"
IF_N3="n3"
IF_N4="eth0" # should be "n4" but not, still work to be done
IF_N6="eth0" # should be "n6" but not, still work to be done
#IF_N6="n3" # test with raphael


CN_DEFAULT_GW=""

####################################### TO REMOVE FROM HERE...
#### mysql chart definitions ####
#MYSQL_REPO="docker.io/mysql"
#MYSQL_TAG="8.0" #previous 5.7 has issues on Rocky sopnode-w1 cluster with docker runtime

#### nrf-amf chart definitions ####
#NRF_REPO="${OAISA_REPO}/oai-nrf"
#NRF_TAG="${CN_TAG}"

#### oai-udr chart definitions ####
#UDR_REPO="${OAISA_REPO}/oai-udr"
#UDR_TAG="${CN_TAG}"

#### oai-udm chart definitions ####
#UDM_REPO="${OAISA_REPO}/oai-udm"
#UDM_TAG="${CN_TAG}"

#### nrf-ausf chart definitions ####
#OAI5G_AUSF="$OAI5G_CORE/oai-ausf"
#AUSF_REPO="${OAISA_REPO}/oai-ausf"
#AUSF_TAG="${CN_TAG}"


#### oai-amf chart definitions ####
#OAI5G_AMF="$OAI5G_CORE/oai-amf"
#AMF_REPO="${OAISA_REPO}/oai-amf"
#AMF_TAG="${CN_TAG}"
#
MULTUS_AMF_N2="$MULTUS_CREATE"
#IP_AMF_N2="$P100.241"
IP_AMF_N2="$SUBNET_N2N3.1"
NETMASK_AMF_N2="24"
GW_AMF_N2=""
ROUTES_AMF_N2=""
IF_NAME_AMF_N2="$IF_NAME_N2N3" 

#### oai-upf chart definitions ####
#OAI5G_UPF="$OAI5G_CORE/oai-upf"
#UPF_REPO="docker.io/r2labuser/oai-upf"
#UPF_TAG="rocky-test90"
#UPF_REPO="${OAISA_REPO}/oai-upf"
#UPF_TAG="${CN_TAG}"
#
MULTUS_UPF_N3="$MULTUS_CREATE"
#IP_UPF_N3="$P100.242" 
IP_UPF_N3="$SUBNET_N2N3.2" 
NETMASK_UPF_N3="24"
GW_UPF_N3=""
ROUTES_UPF_N3=""
IF_NAME_UPF_N3="$IF_NAME_N2N3"
#
MULTUS_UPF_N4="false"
IP_UPF_N4="" 
NETMASK_UPF_N4=""
GW_UPF_N4=""
ROUTES_UPF_N4=""
IF_NAME_UPF_N4=""
#
MULTUS_UPF_N6="false"
IP_UPF_N6="" 
NETMASK_UPF_N6=""
GW_UPF_N6=""
ROUTES_UPF_N6=""
IF_NAME_UPF_N6="" 

#### oai-smf chart definitions ####
#OAI5G_SMF="$OAI5G_CORE/oai-smf"
#SMF_REPO="${OAISA_REPO}/oai-smf"
#SMF_TAG="${CN_TAG}"
MULTUS_SMF_N4="false"
IP_SMF_N4="" 
NETMASK_SMF_N4=""
GW_SMF_N4=""
ROUTES_SMF_N4=""
IF_NAME_SMF_N4="" 
IP_DNS1="138.96.0.210"
IP_DNS2="193.51.196.138"
IP_CSCF="127.0.0.1" # unused but without setting an IP, the SMF pod crashes!

################################ oai-gnb chart parameters ########################
OAI5G_RAN="$OAI5G_CHARTS/oai-5g-ran"
#
R2LAB_REPO="docker.io/r2labuser"
#RAN_TAG="2023.w37"
#RAN_TAG="2024.w02-rocky9.3"
#RAN_TAG="2023.w02-ci"
RAN_TAG="2024.w06"
GNB_NAME="gNB-r2lab"
#IP_GNB_N2N3="$P100.243"
IP_GNB_N2N3="$SUBNET_N2N3.3"
IF_NAME_GNB_N2="$IF_NAME_N2N3"
IF_NAME_GNB_N3="" # unused for current scenario with same PHY network interface for N2/N3
NETMASK_GNB_N2="24"
NETMASK_GNB_N3=""
NETMASK_GNB_RU="24"

#### rfsim RU case ####
#GNB_REPO_rfsim="${OAISA_REPO}/oai-gnb"
GNB_REPO_rfsim="${R2LAB_REPO}/oai-gnb"
GNB_TAG_rfsim="${RAN_TAG}"
CONF_rfsim="gnb.sa.band78.106prb.rfsim.2x2.conf" 
OPTIONS_rfsim="--sa -E --rfsim --log_config.global_log_options level,nocolor,time"

#### b2xx RU case ####
#GNB_REPO_b2xx="${OAISA_REPO}/oai-gnb"
GNB_REPO_b2xx="${R2LAB_REPO}/oai-gnb"
#GNB_TAG_b2xx="2023.w37"
GNB_TAG_b2xx="${RAN_TAG}"
#CONF_b210="gnb.sa.band78.51prb.usrpb200.conf"
CONF_b210="gnb.sa.band78.fr1.51PRB.usrpb210-new.conf"
#OPTIONS_b2xx="--sa --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"
OPTIONS_b2xx="--sa -E --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"

#### n3xx RU case ####
#GNB_REPO_n3xx="${OAISA_REPO}/oai-gnb"
GNB_REPO_n3xx="${R2LAB_REPO}/oai-gnb"
GNB_TAG_n3xx="${RAN_TAG}"
#CONF_n3xx="gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf"
CONF_n320="gnb.sa.band78.106prb.usrpn310.ddsuu-2x2.conf"
CONF_n300="gnb.sa.band78.106prb.usrpn310.ddsuu-2x2.conf"
#OPTIONS_n3xx="--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 0,2,4,6,8,10,12,14,16 --log_config.global_log_options level,nocolor,time"
OPTIONS_n3xx="--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"
IP_GNB_SFP1="192.168.10.132"
IP_GNB_SFP2="192.168.20.132"
MTU_n3xx="9000"
IF_NAME_n3xx_1="$IF_NAME_VLAN10"
IF_NAME_n3xx_2="$IF_NAME_VLAN20"
ADDRS_n300="addr=192.168.10.129,second_addr=192.168.20.129"
ADDRS_n320="addr=192.168.10.130,second_addr=192.168.20.130"

#### aw2s RU case ####
#GNB_REPO_aw2s="docker.io/oaisoftwarealliance/oai-gnb"
GNB_REPO_aw2s="${R2LAB_REPO}/oai-gnb-aw2s"
#GNB_TAG_aw2s="2023.w49"
GNB_TAG_aw2s="${RAN_TAG}"
#CONF_jaguar="oai-gNB-n78_50M_DDDSU.conf"
CONF_jaguar="gnb.sa.band78.51prb.aw2s.ddsuu.conf"
#CONF_panther="oai-gNB-n78_50M_DDDSU.conf"
CONF_panther="gnb.sa.band78.51prb.aw2s.ddsuu.conf"
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
IP_NRUE="$SUBNET_N2N3.4"
NETMASK_NRUE="24"
IF_NAME_NRUE="$IF_NAME_N2N3"
NRUE_USRP="rfsim"

###################### Scenario with External Core Network #######################


# If an external Core Network is used (i.e., GNB_ONLY is "true")
# then, configure the following parameters
if [[ $GNB_ONLY = "true" ]]; then
    # Set the external AMF IP address
    IP_AMF_N2="172.22.10.6" # external AMF IP address, e.g., "172.22.10.6"
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
	    "net-100")
		PREFIX=$PREFIX"00:";;
	    *)  PREFIX=$PREFIX"01:";;
	esac
	case $NODE_AMF_SGPWU in
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
    cat > /tmp/@mode@-values.sed <<EOF
s|@PRIVILEGED@|$LOGS|
s|@TCPDUMP_CONTAINER@|$LOGS|
s|@START_TCPDUMP@|$PCAP|
s|@SHAREDVOLUME@|$PCAP|
s|@CN_DEFAULT_GW@|$CN_DEFAULT_GW|
s|@MULTUS_AMF_N2@|$MULTUS_AMF_N2|
s|@IP_AMF_N2@|$IP_AMF_N2|
s|@NETMASK_AMF_N2@|$NETMASK_AMF_N2|
s|@MAC_AMF_N2@|$(gener-mac)|
s|@GW_AMF_N2@|$GW_AMF_N2|
s|@ROUTES_AMF_N2@|$ROUTES_AMF_N2|
s|@IF_NAME_AMF_N2@|$IF_NAME_AMF_N2|
s|@NODE_AMF@|"$NODE_AMF_UPF"|
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
s|@MULTUS_SMF_N4@|$MULTUS_SMF_N4|
s|@IP_SMF_N4@|$IP_SMF_N4|
s|@NETMASK_SMF_N4@|$NETMASK_SMF_N4|
s|@MAC_SMF_N4@|$(gener-mac)|
s|@GW_SMF_N4@|$GW_SMF_N4|
s|@ROUTES_SMF_N4@|$ROUTES_SMF_N4|
s|@IF_NAME_SMF_N4@|$IF_NAME_SMF_N4|
s|@NODE_SMF@||
EOF
    cp "$OAI5G_@MODE@"/values.yaml /tmp/@mode@_values.yaml-orig
    echo "(Over)writing $OAI5G_@MODE@/values.yaml"
    sed -f /tmp/@mode@-values.sed < /tmp/@mode@_values.yaml-orig > "$OAI5G_@MODE@"/values.yaml
    diff /tmp/@mode@_values.yaml-orig "$OAI5G_@MODE@"/values.yaml

    echo "Configuring chart $OAI5G_@MODE@/config.yaml for R2lab"
    cat > /tmp/@mode@-config.sed <<EOF
s|@IF_N2@|$IF_N2|
s|@IF_N3@|$IF_N3|
s|@IF_N4@|$IF_N4|
s|@IF_N6@|$IF_N6|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@TAC@|0x0001|
s|@DNN0@|$DNN|
s|@IP_DNS1@|$IP_DNS1|
s|@IP_DNS2@|$IP_DNS2|
EOF
    cp "$OAI5G_@MODE@"/config.yaml /tmp/@mode@_config.yaml-orig
    echo "(Over)writing $OAI5G_@MODE@/config.yaml"
    sed -f /tmp/@mode@-config.sed < /tmp/@mode@_config.yaml-orig > "$OAI5G_@MODE@"/config.yaml
    diff /tmp/@mode@_config.yaml-orig "$OAI5G_@MODE@"/config.yaml
    
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
    DIR_GNB_DEST="$PREFIX_DEMO/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb"
    DIR_TEMPLATES="$DIR_GNB_DEST/templates"

    SED_CONF_FILE="/tmp/gnb_conf.sed"
    SED_VALUES_FILE="/tmp/oai-gnb-values.sed"

    # Configure general parameters for values.yaml
    MULTUS_GNB_N2="$MULTUS_CREATE"
    GNB_N2_IF_NAME="n2"
    GNB_N2_IP_ADDRESS="$IP_GNB_N2N3/24"
    MULTUS_GNB_N3="false"
    GNB_N3_IF_NAME="n2"
    GNB_N3_IP_ADDRESS="$IP_GNB_N2N3/24"
    
    # Configure RRU specific parameters for values.yaml chart
    if [[ "$RRU" = "b210" ]]; then
	MULTUS_GNB_RU1="false"
	MULTUS_GNB_RU2="false"
	RRU_TYPE="b2xx"
	ADD_OPTIONS_GNB="$OPTIONS_b2xx"
	QOS_GNB_DEF="false"

    elif [[ "$RRU" = "n300" || "$RRU" = "n320" ]]; then
	if [[ "$RRU" = "n300" ]]; then
	    SDR_ADDRS="$ADDRS_n300"
	elif [[ "$RRU" = "n320" ]]; then
	    SDR_ADDRS="$ADDRS_n320"
	fi
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
	if [[ "$RRU" = "jaguar" ]]; then
	    ADDR_aw2s="$ADDR_jaguar"
	else
	    ADDR_aw2s="$ADDR_panther"
	fi
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
	ADD_OPTIONS_GNB="$OPTIONS_RFSIM"
	QOS_GNB_DEF="false"

    else
	echo "Unknown rru selected: $RRU"
	usage
    fi
    
    CONF_ORIG=$DIR_CONF/$(eval echo \"\${CONF_$RRU}\")
    GNB_REPO=$(eval echo \"\${GNB_REPO_$RRU_TYPE}\")
    GNB_TAG=$(eval echo \"\${GNB_TAG_$RRU_TYPE}\")
    GNB_NAME="${GNB_NAME}_${RRU}"

    echo "Insert gNB conf file $CONF_ORIG in configmap.yaml"
    # Keep the 8 first lines of configmap.yaml
    head -8  "$DIR_TEMPLATES"/configmap.yaml > /tmp/configmap.yaml
    # Add a 6-characters margin to gnb.conf
    awk '$0="      "$0' "$CONF_ORIG" > /tmp/gnb.conf
    # Append the modified gnb.conf to /tmp/configmap.yaml
    cat /tmp/gnb.conf >> /tmp/configmap.yaml
    mv /tmp/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml

    echo "First configure gnb.conf within configmap.yaml"
    # remove NSSAI sd info for PLMN and add other parameters for RUs
    cat > "$SED_CONF_FILE" <<EOF
s|@GNB_NAME@|$GNB_NAME|
s|@TAC@|$TAC|
s|@MCC@|$MCC|
s|@MNC@|$MNC|
s|@SST@|1|
s|@GNB_N2_IF_NAME@|$GNB_N2_IF_NAME|
s|@GNB_N2_IP_ADDRESS@|$GNB_N2_IP_ADDRESS|
s|@GNB_N3_IF_NAME@|$GNB_N3_IF_NAME|
s|@GNB_N3_IP_ADDRESS@|$GNB_N3_IP_ADDRESS|
s|@AW2S_IP_ADDRESS@|$ADDR_aw2s|
s|@GNB_AW2S_IP_ADDRESS@|$IP_GNB_aw2s|
s|@GNB_AW2S_LOCAL_IF_NAME@|$GNB_aw2s_LOCAL_IF_NAME|
s|@SDR_ADDRS@|$SDR_ADDRS,clock_source=internal,time_source=internal|
EOF
    cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
    sed -f "$SED_CONF_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
    echo "Display new $DIR_TEMPLATES/configmap.yaml"
    cat "$DIR_TEMPLATES"/configmap.yaml


    # Configure gnb values.yaml chart
    DIR="$OAI5G_RAN/oai-gnb"

    echo "Then configure oai-gnb charts"
    cat > "$SED_VALUES_FILE" <<EOF
s|@GNB_REPO@|$GNB_REPO|
s|@GNB_TAG@|$GNB_TAG|
s|@DEFAULT_GW_GNB@|$DEFAULT_GW_GNB|
s|@MULTUS_GNB_N2@|$MULTUS_GNB_N2|
s|@AMF_IP_ADDRESS@|$IP_AMF_N2|
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
s|@NRUE_USRP@|$NRUE_USRP|
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
    echo "Running start-gnb() on $NS namespace with NODE_GNB=$NODE_GNB and rru=$RRU"

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
    echo "helm --namespace=$NS uninstall oai-5g-@mode@"
    helm --namespace=$NS uninstall oai-5g-@mode@ 
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

AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
AMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-amf $AMF_POD_NAME running with IP $AMF_eth0_IP"
kubectl --namespace $NS -c amf logs $AMF_POD_NAME > "$prefix"/amf-"$DATE".logs

AUSF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
AUSF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-ausf $AUSF_POD_NAME running with IP $AUSF_eth0_IP"
kubectl --namespace $NS -c ausf logs $AUSF_POD_NAME > "$prefix"/ausf-"$DATE".logs

GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
GNB_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-gnb $GNB_POD_NAME running with IP $GNB_eth0_IP"
kubectl --namespace $NS -c gnb logs $GNB_POD_NAME > "$prefix"/gnb-"$DATE".logs

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

if [[ "$RRU" = "rfsim" ]]; then
NRUE_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
NRUE_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-nr-ue $NRUE_POD_NAME running with IP $NRUE_eth0_IP"
kubectl --namespace $NS -c nr-ue logs $NRUE_POD_NAME > "$prefix"/nr-ue-"$DATE".logs
fi

echo "Retrieve gnb config from the pod"
kubectl -c gnb cp $NS/$GNB_POD_NAME:/tmp/gnb.conf $prefix/gnb.conf || true

echo "Retrieve nrL1_stats.log, nrMAC_stats.log and nrRRC_stats.log from gnb pod"
kubectl -c gnb cp $NS/$GNB_POD_NAME:nrL1_stats.log $prefix/nrL1_stats.log"$DATE" || true
kubectl -c gnb cp $NS/$GNB_POD_NAME:nrMAC_stats.log $prefix/nrMAC_stats.log"$DATE" || true
kubectl -c gnb cp $NS/$GNB_POD_NAME:nrRRC_stats.log $prefix/nrRRC_stats.log"$DATE" || true
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

