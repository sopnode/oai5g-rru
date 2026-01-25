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
export NODE_AMF=${NODE_AMF_UPF}
export NODE_UPF=${NODE_AMF_UPF}
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
export SLICE1_5QI="@DEF_SLICE1_5QI@"
export SLICE1_UPLINK="@DEF_SLICE1_UPLINK@"
export SLICE1_DOWNLINK="@DEF_SLICE1_DOWNLINK@"
export SLICE2_SST="@DEF_SLICE2_SST@"
export SLICE2_SD="@DEF_SLICE2_SD@"
export SLICE2_5QI="@DEF_SLICE2_5QI@"
export SLICE2_UPLINK="@DEF_SLICE2_UPLINK@"
export SLICE2_DOWNLINK="@DEF_SLICE2_DOWNLINK@"
export GNB_ID="@DEF_GNB_ID@"
#
################SST0="@DEF_SST0@"
export FULL_KEY="@DEF_FULL_KEY@"
export OPC="@DEF_OPC@"
export RFSIM_IMSI="@DEF_RFSIM_IMSI@"
export RFSIM_IMSI_UE2="@DEF_RFSIM_IMSI_UE2@"
export RFSIM_IMSI_UE3="@DEF_RFSIM_IMSI_UE3@"
#
PREFIX_DEMO="@DEF_PREFIX_DEMO@" # Directory in which all scripts will be copied on the k8s server to run the demo
#
#################################################################################
##################################################################################
TMP="/tmp/tmp.$USER" # directory used to store logs and ither temp files
mkdir -p "$TMP"
PREFIX_STATS="$TMP/oai5g-stats"
OAISA_REPO="docker.io/oaisoftwarealliance" # currently unused

# Interfaces names of VLANs in sopnode servers
# Local network interface is defined in prepare-demo-oai.sh ("net-30" for sopnode-{l1|w1})
IF_NAME_CORE_N2N3="@DEF_LOCAL_CORE_INTERFACE@" 
IF_NAME_RAN_N2N3="@DEF_LOCAL_RAN_INTERFACE@" 
IF_NAME_N4="@DEF_LOCAL_CORE_INTERFACE@" 
IF_NAME_N6="@DEF_LOCAL_CORE_INTERFACE@" 
IF_NAME_N9="@DEF_LOCAL_CORE_INTERFACE@" 
IF_NAME_E1="@DEF_LOCAL_RAN_INTERFACE@" 
IF_NAME_E2="@DEF_LOCAL_RAN_INTERFACE@" 
IF_NAME_F1="@DEF_LOCAL_RAN_INTERFACE@"
IF_NAME_SBI="@DEF_LOCAL_CORE_INTERFACE@"
IF_NAME_TS="@DEF_LOCAL_CORE_INTERFACE@"

############# Running-mode dependent parameters configuration ###############
#
set_if_name() {
    local multus=$1
    local default_if=$2
    local multus_if=$3
    if [ "$multus" = "true" ]; then
        echo "${multus_if}"
    else
        echo "${default_if}"
    fi
}

if [[ $RUN_MODE = "full" ]]; then
    # CN and RAN pods enabled
    SUBNET_N2N3="192.168.3"
    SUBNET_N4="192.168.24"
    SUBNET_N6="192.168.22"
    SUBNET_N9="192.168.23"
    SUBNET_SBI="172.21.8"
    SUBNET_TS="172.21.6"
    NETMASK_N2N3="24"
    NETMASK_N4="24"
    NETMASK_N6="24"
    NETMASK_N9="24"
    NETMASK_SBI="22"
    NETMASK_TS="22"
    #
    export ENABLED_MYSQL="true"
    export ENABLED_NRF="true"
    export ENABLED_NSSF="true"
    export ENABLED_UDM="true"
    export ENABLED_UDR="true"
    export ENABLED_AUSF="true"
    #
    export NFS_NRF_HOST="oai-nrf"
    # amf chart
    export ENABLED_AMF="true"
    export MULTUS_AMF="true"
    ## amf n2 IF
    export MULTUS_AMF_N2="true"
    export IF_NAME_AMF_N2="${IF_NAME_CORE_N2N3}"
    export NAME_AMF_N2=$(set_if_name "${MULTUS_AMF_N2}" "eth0" "n2")
    export IP_AMF_N2="${SUBNET_N2N3}.201"
    export NETMASK_AMF_N2="${NETMASK_N2N3}"
    export ROUTES_AMF_N2=""
    export DEF_ROUTE_AMF_N2=""
    ## amf sbi IF
    export MULTUS_AMF_SBI="false"
    export IF_NAME_AMF_SBI="${IF_NAME_SBI}"
    export NAME_AMF_SBI=$(set_if_name "${MULTUS_AMF_SBI}" "eth0" "sbi")
    export IP_AMF_SBI="${SUBNET_SBI}.91"
    export NETMASK_AMF_SBI="${NETMASK_SBI}"
    export GW_AMF_SBI=""
    # upf chart
    export ENABLED_UPF="true"
    export MULTUS_UPF="true"
    ## upf n3 IF
    export MULTUS_UPF_N3="true"
    export IF_NAME_UPF_N3="${IF_NAME_CORE_N2N3}"
    export NAME_UPF_N3=$(set_if_name "${MULTUS_UPF_N3}" "eth0" "n3")
    export IP_UPF_N3="${SUBNET_N2N3}.202"
    export NETMASK_UPF_N3="${NETMASK_N2N3}"
    export DEF_ROUTE_UPF_N3=""
    ## upf n4 IF
    export MULTUS_UPF_N4="false"
    export IF_NAME_UPF_N4="${IF_NAME_N4}"
    export NAME_UPF_N4=$(set_if_name "${MULTUS_UPF_N4}" "eth0" "n4")
    export IP_UPF_N4="${SUBNET_N4}.2"
    export NETMASK_UPF_N4="${NETMASK_N4}"
    ## upf n6 IF
    export MULTUS_UPF_N6="true"
    export IF_NAME_UPF_N6="${IF_NAME_N6}"
    export NAME_UPF_N6=$(set_if_name "${MULTUS_UPF_N6}" "eth0" "n6")
    export IP_UPF_N6="${SUBNET_N6}.2"
    export NETMASK_UPF_N6="${NETMASK_N6}"
    ## upf n9 IF
    export MULTUS_UPF_N9="false"
    export IF_NAME_UPF_N9="${IF_NAME_N9}"
    export NAME_UPF_N9=$(set_if_name "${MULTUS_UPF_N9}" "eth0" "n9")
    export IP_UPF_N9="${SUBNET_N9}.2"
    export NETMASK_UPF_N9="${NETMASK_N9}"
    ## upf sbi IF
    export MULTUS_UPF_SBI="false"
    export IF_NAME_UPF_SBI="${IF_NAME_SBI}"
    export NAME_UPF_SBI=$(set_if_name "${MULTUS_UPF_SBI}" "eth0" "sbi")
    export IP_UPF_SBI="${SUBNET_SBI}.91"
    export NETMASK_UPF_SBI="${NETMASK_SBI}"
    export GW_UPF_SBI=""
    ## 
    # TS (Traffic Server) chart
    export ENABLE_SNAT="yes"
    export ENABLED_TS="true"
    ## "external" IF
    export MULTUS_TS="true"
    export IP_TS="${SUBNET_TS}.99"
    export NETMASK_TS="22"
    export IF_NAME_TS="${IF_NAME_TS}"
    export NAME_TS=$(set_if_name "${MULTUS_TS}" "eth0" "external")
    export DEF_ROUTE_TS=""
    export NODE_TS="${NODE_AMF_UPF}"
    # smf chart
    export ENABLED_SMF="true"
    export MULTUS_SMF="false"
    ## n4 IF
    export MULTUS_SMF_N4="false"
    export IF_NAME_SMF_N4="${IF_NAME_N4}"
    export NAME_SMF_N4=$(set_if_name "${MULTUS_SMF_N4}" "eth0" "n4")
    export IP_SMF_N4="${SUBNET_N4}.3" 
    export NETMASK_SMF_N4="${NETMASK_N4}"
    export DEF_ROUTE_SMF_N4=""
    ## smf sbi IF
    export MULTUS_SMF_SBI="false"
    export IF_NAME_SMF_SBI="${IF_NAME_SBI}"
    export NAME_SMF_SBI=$(set_if_name "${MULTUS_SMF_SBI}" "eth0" "sbi")
    export IP_SMF_SBI="${SUBNET_SBI}.92"
    export NETMASK_SMF_SBI="${NETMASK_SBI}"
    export GW_SMF_SBI=""
    #
    export IP_DNS1="138.96.0.210" # unused TBD !
    export IP_DNS2="193.51.196.138" # unused TBD !
    # RAN charts
    export HOST_AMF="${IP_AMF_N2}"
    export MULTUS_GNB_N2="true"
    export IF_NAME_GNB_N2="${IF_NAME_RAN_N2N3}"
    export IP_GNB_N2="${SUBNET_N2N3}.203"
    export MULTUS_GNB_N3="false"
    export IF_NAME_GNB_N3="${IF_NAME_RAN_N2N3}"
    if [[ $GNB_MODE = 'cucpup' ]]; then
	export MULTUS_CUUP_N3="true"
	export IP_GNB_N3="${SUBNET_N2N3}.204"
	export IF_NAME_CUUP_N3="${IF_NAME_RAN_N2N3}"
    else
	export IP_GNB_N3="${SUBNET_N2N3}.203"
    fi

else
    # Local RAN, External MYSQL/UDR/UDM/AUSF/AMF/SMF/UPF
    ENABLE_SNAT="off" # "yes" or "off"
    if [[ $RUN_MODE = "gnb-upf" ]]; then
	# Local RAN and local UPF
	export SUBNET_N2N3="172.21.10"
	export NETMASK_N2N3="26"
	IF_NAME_RAN_N2N3="br-slices"
	#
	export ENABLED_MYSQL="false"
	export ENABLED_NRF="false"
	export NFS_NRF_HOST="${SUBNET_N2N3}.203"
	export ENABLED_NSSF="false"
	export ENABLED_UDR="false"
	export ENABLED_UDM="false"
	export ENABLED_AUSF="false"
	export ENABLED_SMF="false"
	export ENABLED_AMF="false"
	# upf
	export ENABLED_UPF="true"
	export NFS_UPF_HOST="oai-upf"
	export IF_SBI="n3"
	export IF_N3="n3"
	export IF_N4="n3"
	export IF_N6="eth0"
	export MULTUS_UPF_N3="true"
	export IP_UPF_N3="${SUBNET_N2N3}.222"
	export NETMASK_UPF_N3="${NETMASK_N2N3}"
	export GW_UPF_N3=""
	export ROUTES_UPF_N3="[{'dst': '10.8.0.0/24','gw': '172.21.10.254'}]"
	export IF_NAME_UPF_N3="${IF_NAME_CORE_N2N3}"
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
	export ENABLED_TS="false"
	# ran charts
	export HOST_AMF="oai-amf"
	export MULTUS_GNB_N2="true"
	export IP_GNB_N2="${SUBNET_N2N3}.223"
	export IF_NAME_GNB_N2="n2"
	export MULTUS_GNB_N3="false"
	if [[ $GNB_MODE = 'cucpup' ]]; then
	    export MULTUS_CUUP_N3="true"
	    export IP_GNB_N3="${SUBNET_N2N3}.224"
	    export IF_NAME_CUUP_N3="n3"
	else
	    export IP_GNB_N3="${SUBNET_N2N3}.223"
	fi
	export IF_NAME_GNB_N3="n2"
	export ROUTES_GNB_N2="" # Set the route for gNB to reach AMF (N2) and UPF (N3)
	#export ROUTES_GNB_N2="[{'dst': '172.21.0.0/16','gw': '192.168.128.129'},{'dst': '192.168.128.0/24','gw': '192.168.128.129'}]"
    else
        # ${RUN_MODE} == "gnb-only"
	# only RAN pods are enabled
	#

	if [[ "${NODE_AMF_UPF}" == "10.10.3.200" ]]; then
	    # Scenario with Open5gs CN
	    export SUBNET_N2N3="10.10.3"
	    export IF_NAME_RAN_N2N3="n3br"
	    export NETMASK_N2N3="24"
	    export MULTUS_GNB_N2="false"
	    export MULTUS_GNB_N3="true"
	    export IF_NAME_GNB_N3="${IF_NAME_RAN_N2N3}"
	    export IP_GNB_N3="${SUBNET_N2N3.205}"
	    export MULTUS_CUCP_N2="true"
	    export IP_CUCP_N2="${SUBNET_N2N3.205}"
	    export MULTUS_CUUP_N3="true"
	    export IP_CUUP_N3="${SUBNET_N2N3.206}"
	else
	    export SUBNET_N2N3="192.168.3"
	    export IF_NAME_RAN_N2N3 # just export the default value
	    export NETMASK_N2N3="24"
	    export MULTUS_GNB_N2="true"
	    export IF_NAME_GNB_N2="${IF_NAME_RAN_N2N3}"
	    export IP_GNB_N2="${SUBNET_N2N3}.203"
	    export MULTUS_GNB_N3="false"
	    export IF_NAME_GNB_N3=""
	    if [[ $GNB_MODE = 'cucpup' ]]; then
		export MULTUS_CUUP_N3="true"
		export IP_GNB_N3="${SUBNET_N2N3}.204"
		export IF_NAME_CUUP_N3="${IF_NAME_RAN_N2N3}"
	    else
		export IP_GNB_N3="${SUBNET_N2N3}.203"
	    fi
	fi
	export HOST_AMF="${SUBNET_N2N3}.200"  # Default AMF IP address
    fi
fi



############################### oai-cn5g chart parameters ########################
#
OAI5G_CHARTS="${PREFIX_DEMO}/charts"
OAI5G_CORE="${OAI5G_CHARTS}/oai-5g-core"
OAI5G_ADVANCE="${OAI5G_CORE}/oai-5g-advance"

export CN_DEFAULT_GW=""

################################ oai-gnb chart parameters ########################
OAI5G_RAN="${OAI5G_CHARTS}/oai-5g-ran"
R2LAB_REPO="docker.io/r2labuser"

export RAN_TAG="2025.w52"

# Default GNB REPO/TAG (can be overrided in rru/${rru}.env)
export GNB_REPO="${R2LAB_REPO}/oai-gnb"
export GNB_TAG="${RAN_TAG}"
export GNB_PULL_POLICY="IfNotPresent"
#
export GNB_FHI72_REPO="${R2LAB_REPO}/oai-gnb-fhi72"
export GNB_FHI72_TAG="${RAN_TAG}"
export GNB_FHI72_PULL_POLICY="IfNotPresent"
#
# F1/F1C/F1U/E1/E2 subnets/netmasks
#
SUBNET_E1="192.168.18"
NETMASK_E1="24"
SUBNET_E2="192.168.85"
NETMASK_E2="24"
SUBNET_F1="172.21.16"
SUBNET_F1C="172.21.6"
SUBNET_F1U="172.21.16"
NETMASK_F1="24"
#
export GNB_NAME="oai-gnb-${RRU}"
export DU_NAME="oai-du-${RRU}"
#
##########################################
# DU/CU SPLIT parameters
##########################################

########## DU specific part ##############
export DU_REPO="${R2LAB_REPO}/oai-gnb" 
export DU_TAG=${RAN_TAG}
export DU_PULL_POLICY=${GNB_PULL_POLICY}
#
export DU_FHI72_REPO="${R2LAB_REPO}/oai-gnb-fhi72"
export DU_FHI72_TAG="${DU_TAG}"
export DU_FHI72_PULL_POLICY="${DU_PULL_POLICY}"
#
export MULTUS_DU_F1C="true"
export IP_DU_F1C="${SUBNET_F1C}.90"
export NETMASK_DU_F1C="${NETMASK_F1}"
export ROUTES_DU_F1C=""
export IF_NAME_DU_F1C="${IF_NAME_F1}"
#
export MULTUS_DU_F1U="true"
export IP_DU_F1U="${SUBNET_F1U}.90"
export NETMASK_DU_F1U="${NETMASK_F1}"
export GW_DU_F1U=""
export ROUTES_DU_F1U=""
export IF_NAME_DU_F1U="${IF_NAME_F1}"
#
export MULTUS_DU_F1="true"
export IP_DU_F1="${SUBNET_F1}.100"
export NETMASK_DU_F1="${NETMASK_F1}"
export GW_DU_F1=""
export ROUTES_DU_F1=""
export IF_NAME_DU_F1="${IF_NAME_F1}"
#
export MULTUS_DU_E2="$FLEXRIC"
export IP_DU_E2="${SUBNET_E2}.91"
export NETMASK_DU_E2="${NETMASK_E2}"
export GW_DU_E2=""
export ROUTES_DU_E2="" 
export IF_NAME_DU_E2="${IF_NAME_E2}"
#
export QOS_DU="true"
export NODE_DU="${NODE_GNB}"
#
########## CU specific part ##############
export CU_REPO="${R2LAB_REPO}/oai-gnb" 
export CU_TAG=${RAN_TAG}
export CU_PULL_POLICY="${GNB_PULL_POLICY}"
#
export MULTUS_CU_F1="true"
export IP_CU_F1="${SUBNET_F1}.92"
export NETMASK_CU_F1="${NETMASK_F1}"
export GW_CU_F1="" 
export ROUTES_CU_F1="" 
export IF_NAME_CU_F1="${IF_NAME_F1}"
#
export MULTUS_CU_N2=${MULTUS_CU_N2:=${MULTUS_GNB_N2}}
export IP_CU_N2=${IP_CU_N2:=${IP_GNB_N2}}
export NETMASK_CU_N2=${NETMASK_CU_N2:=${NETMASK_N2N3}}
export GW_CU_N2=${GW_CU_N2:=""}
export ROUTES_CU_N2=${ROUTES_CU_N2:=""}
export IF_NAME_CU_N2=${IF_NAME_CU_N2:=${IF_NAME_RAN_N2N3}}
#
export MULTUS_CU_N3=${MULTUS_CU_N3:=${MULTUS_GNB_N3}}
export IP_CU_N3=${IP_CU_N3:=${IP_GNB_N3}}
export NETMASK_CU_N3=${NETMASK_CU_N3:=${NETMASK_N2N3}}
export GW_CU_N3=${GW_CU_N3:=""}
export ROUTES_CU_N3=${ROUTES_CU_N3:=""}
export IF_NAME_CU_N3=${IF_NAME_CU_N3:=${IF_NAME_RAN_N2N3}}
#
export MULTUS_CU_E2="$FLEXRIC"
export IP_CU_E2="${SUBNET_E2}.93"
export NETMASK_CU_E2="${NETMASK_E2}"
export GW_CU_E2=""
export ROUTES_CU_E2="" 
export IF_NAME_CU_E2="${IF_NAME_E2}"
#
export ADD_OPTIONS_CU="--log_config.global_log_options level,nocolor,time"
export QOS_CU="true"
export NODE_CU="${NODE_GNB}" 

# NODE_CU is defined above and also the same for CUCP/CUUP
#
########## CU-CP specific part ##############
export CUCP_REPO="${R2LAB_REPO}/oai-gnb" 
export CUCP_TAG=${RAN_TAG}
export CUCP_PULL_POLICY=${GNB_PULL_POLICY}
#
export MULTUS_CUCP_E1="true"
export IP_CUCP_E1="${SUBNET_E1}.12"
export NETMASK_CUCP_E1="${NETMASK_E1}"
export GW_CUCP_E1=""
export ROUTES_CUCP_E1=""
export IF_NAME_CUCP_E1="${IF_NAME_E1}"
#
export MULTUS_CUCP_E2="$FLEXRIC" # E2 only used if FLEXRIC is true
export IP_CUCP_E2="${SUBNET_E2}.93"
export NETMASK_CUCP_E2="${NETMASK_E2}"
export GW_CUCP_E2=""
export ROUTES_CUCP_E2="" 
export IF_NAME_CUCP_E2="${IF_NAME_E2}"
#
export MULTUS_CUCP_N2=${MULTUS_CUCP_N2:=${MULTUS_GNB_N2}}
export IP_CUCP_N2=${IP_CUCP_N2:=${IP_GNB_N2}}
export NETMASK_CUCP_N2=${NETMASK_CUCP_N2:=${NETMASK_N2N3}}
export GW_CUCP_N2=${GW_CUCP_N2:=""}
export ROUTES_CUCP_N2=${ROUTES_CUCP_N2:=""}
export IF_NAME_CUCP_N2=${IF_NAME_CUCP_N2:=${IF_NAME_RAN_N2N3}}
#
export MULTUS_CUCP_F1C="true"
export IP_CUCP_F1C="${SUBNET_F1C}.92"
export NETMASK_CUCP_F1C="${NETMASK_F1}"
export GW_CUCP_F1C=""
export ROUTES_CUCP_F1C=""
export IF_NAME_CUCP_F1C="${IF_NAME_F1}"
#
export ADD_OPTIONS_CUCP="--log_config.global_log_options level,nocolor,time"
export NAME_CUCP="oai-cu-cp"
export QOS_CUCP="true"
export NODE_CUCP="${NODE_CU}"
#
########## CU-UP specific part ##############
export CUUP_REPO="${R2LAB_REPO}/oai-nr-cuup"
export CUUP_TAG="${RAN_TAG}"
export CUUP_PULL_POLICY="${GNB_PULL_POLICY}"
#
export MULTUS_CUUP_E1="true"
export IP_CUUP_E1="${SUBNET_E1}.13"
export NETMASK_CUUP_E1="${NETMASK_E1}"
export GW_CUUP_E1=""
export ROUTES_CUUP_E1="" 
export IF_NAME_CUUP_E1="${IF_NAME_E1}"
#
export MULTUS_CUUP_E2="$FLEXRIC"
export IP_CUUP_E2="${SUBNET_E2}.92"
export NETMASK_CUUP_E2="${NETMASK_E2}"
export GW_CUUP_E2=""
export ROUTES_CUUP_E2="" 
export IF_NAME_CUUP_E2="${IF_NAME_E2}"
#
export MULTUS_CUUP_N3=${MULTUS_CUUP_N3:=${MULTUS_GNB_N3}}
export IP_CUUP_N3=${IP_CUUP_N3:=${IP_GNB_N3}}
export NETMASK_CUUP_N3=${NETMASK_CUUP_N3:=${NETMASK_N2N3}}
export GW_CUUP_N3=${GW_CUUP_N3:=""}
export ROUTES_CUUP_N3=${ROUTES_CUUP_N3:=""}
export IF_NAME_CUUP_N3=${IF_NAME_CUUP_N3:=${IF_NAME_RAN_N2N3}}
#
export MULTUS_CUUP_F1U="true"
export IP_CUUP_F1U="${SUBNET_F1U}.93"
export NETMASK_CUUP_F1U="${NETMASK_F1}"
export GW_CUUP_F1U="" # "172.21.19.254"
export ROUTES_CUUP_F1U=""
export IF_NAME_CUUP_F1U="${IF_NAME_F1}"
#
export ADD_OPTIONS_CUUP="--log_config.global_log_options level,nocolor,time"
export HOST_CUCP="${IP_CUCP_E1}" # "oai-cu-cp" 
export QOS_CUUP="true"
export NODE_CUUP="${NODE_CU}"
#
if [[ $GNB_MODE = 'cucpup' ]]; then
    export CU_HOST_FROM_DU="${IP_CUCP_F1C}"
    export CU_HOST_FROM_CUUP="${IP_CUCP_E1}"
else
    export CU_HOST_FROM_DU="${IP_CU_F1}"
fi
#
########## GNB Monolithic specific part ################
#
export NETMASK_GNB_N2="${NETMASK_N2N3}"
export NETMASK_GNB_N3="${NETMASK_N2N3}"
export NETMASK_GNB_RU="24"
#
export MULTUS_GNB_E2="$FLEXRIC"
export IP_GNB_E2="${SUBNET_E2}.94"
export NETMASK_GNB_E2="${NETMASK_E2}"
export GW_GNB_E2=""
export ROUTES_GNB_E2="" 
export IF_NAME_GNB_E2="${IF_NAME_E2}"
#
export QOS_GNB="true"


########################### oai-nr-ue rfsim chart parameters #####################
export NRUE_REPO="${R2LAB_REPO}/oai-nr-ue"
export NRUE_TAG="${RAN_TAG}"
export MULTUS_NRUE="true"
case "${GNB_MODE}" in
    'monolithic')
	export SUBNET_NRUE="${SUBNET_N2N3}"
	export NETMASK_NRUE="${NETMASK_N2N3}"
	export IF_NAME_NRUE="${IF_NAME_RAN_N2N3}"
	;;
    *)
	export SUBNET_NRUE="${SUBNET_F1}"
	export NETMASK_NRUE="${NETMASK_F1}"
	export IF_NAME_NRUE="${IF_NAME_DU_F1}"
	;;
esac
export IP_NRUE="${SUBNET_NRUE}.210"
export IP_NRUE2="${SUBNET_NRUE}.211"
export IP_NRUE3="${SUBNET_NRUE}.212"
export ADD_OPTIONS_NRUE="--rfsim -C 3619200000 -r 106 --numerology 1 --ssb 516 -E  --log_config.global_log_options level,nocolor,time" 
export QOS_NRUE="false"
export NODE_NRUE="${NODE_GNB}"


########################### oai-flexric chart parameters #####################
FLEXRIC_REPO="ghcr.io/ziyad-mabrouk/oai-flexric"
#FLEXRIC_REPO="oaisoftwarealliance/oai-flexric"
export FLEXRIC_TAG="test"
#FLEXRIC_TAG="latest"
export FLEXRIC_PULL_POLICY="Always"
export HOST_FLEXRIC="oai-flexric"


#################################################################################
#                       OAI-CN charts configuration
#################################################################################

configure-oai-5g-advance() {

    values_file="${OAI5G_ADVANCE}/values.yaml"
    config_file="${OAI5G_ADVANCE}/config.yaml"

    echo "======================="

    # ---- Backup ----
    cp "$values_file" "$TMP/values.yaml-orig"
    cp "$config_file" "$TMP/config.yaml-orig"

    #####################################
    # ---- values.yaml CONFIGURATION ----
    #####################################
    
    # ---- GLOBAL ----
    yq -i '.global.IP_NRF = strenv(NFS_NRF_HOST)' "$values_file"

    # ---- NETWORK FUNCTIONS ----
    NF_NAMES=(oai-nrf oai-amf oai-smf oai-upf oai-udm oai-udr oai-ausf oai-lmf oai-traffic-server)

    for nf in "${NF_NAMES[@]}"; do
        NF_UPPER=$(echo "${nf#*-}" | tr a-z A-Z | tr '-' '_')

        # ---- nodeName ----
	# Form the name of the variable you want to reference
	export NODE_NAME=$(eval echo \"\${NODE_$NF_UPPER}\")
	export ENABLED=$(eval echo \"\${ENABLED_$NF_UPPER}\")

	# Proceed with your yq command
	yq -i ".${nf}.nodeName = strenv(NODE_NAME)" "$values_file"

        # ---- start / tcpdump / sharedvolume ----
        yq -i "
          .${nf}.enabled = (strenv(ENABLED) == \"true\") |
          .${nf}.start.tcpdump = (strenv(PCAP) == \"true\") |
          .${nf}.includeTcpDumpContainer = (strenv(LOGS) == \"true\") |
          .${nf}.persistent.sharedvolume = (strenv(PCAP) == \"true\")
        " "$values_file"

        # ---- Multus interfaces ----
        case "$nf" in
            oai-amf)
                yq -i "
                  .${nf}.multus.enabled = (strenv(MULTUS_AMF) == \"true\") |
                  .${nf}.multus.interfaces[0].hostInterface = \
		  strenv(IF_NAME_AMF_N2) |
                  .${nf}.multus.interfaces[0].ipAdd = strenv(IP_AMF_N2) |
                  .${nf}.multus.interfaces[0].netmask = strenv(NETMASK_AMF_N2) |
                  .${nf}.multus.interfaces[0].routes = strenv(ROUTES_AMF_N2) |
                  .${nf}.multus.interfaces[0].defaultRoute = \
		  strenv(DEF_ROUTE_AMF_N2) |
                  .${nf}.multus.interfaces[0].enabled = \
		  (strenv(MULTUS_AMF_N2) == \"true\") |
                  .${nf}.multus.interfaces[0].type = \"macvlan\"
                " "$values_file"
                yq -i "
                  .${nf}.multus.interfaces[1].hostInterface = \
		  strenv(IF_NAME_AMF_SBI) |
                  .${nf}.multus.interfaces[1].ipAdd = strenv(IP_AMF_SBI) |
                  .${nf}.multus.interfaces[1].netmask = strenv(NETMASK_AMF_SBI) |
                  .${nf}.multus.interfaces[1].gateway = strenv(GW_AMF_SBI) |
                  .${nf}.multus.interfaces[1].enabled = \
		  (strenv(MULTUS_AMF_SBI) == \"true\") |
                  .${nf}.multus.interfaces[1].type = \"macvlan\"
                " "$values_file"
                ;;
            oai-upf)
                yq -i "
                  .${nf}.multus.enabled = (strenv(MULTUS_UPF) == \"true\") |
                  .${nf}.multus.interfaces[0].hostInterface = \
		  strenv(IF_NAME_UPF_N3) |
                  .${nf}.multus.interfaces[0].ipAdd = strenv(IP_UPF_N3) |
                  .${nf}.multus.interfaces[0].netmask = strenv(NETMASK_UPF_N3) |
                  .${nf}.multus.interfaces[0].gateway = strenv(GW_UPF_N3) |
                  .${nf}.multus.interfaces[0].routes = strenv(ROUTES_UPF_N3) |
                  .${nf}.multus.interfaces[0].defaultRoute = \
		  strenv(DEF_ROUTE_UPF_N3) |
                  .${nf}.multus.interfaces[0].enabled = \
                  (strenv(MULTUS_UPF_N3) == \"true\") |
                  .${nf}.multus.interfaces[0].type = \"macvlan\"
                " "$values_file"
                yq -i "
                  .${nf}.multus.interfaces[1].hostInterface = \
		  strenv(IF_NAME_UPF_N4) |
                  .${nf}.multus.interfaces[1].ipAdd = strenv(IP_UPF_N4) |
                  .${nf}.multus.interfaces[1].netmask = strenv(NETMASK_UPF_N4) |
                  .${nf}.multus.interfaces[1].gateway = strenv(GW_UPF_N4) |
                  .${nf}.multus.interfaces[1].routes = strenv(ROUTES_UPF_N4) |
                  .${nf}.multus.interfaces[1].enabled = \
                  (strenv(MULTUS_UPF_N4) == \"true\") |
                  .${nf}.multus.interfaces[1].type = \"macvlan\"
                " "$values_file"
                yq -i "
                  .${nf}.multus.interfaces[2].hostInterface = \
		  strenv(IF_NAME_UPF_N6) |
                  .${nf}.multus.interfaces[2].ipAdd = strenv(IP_UPF_N6) |
                  .${nf}.multus.interfaces[2].netmask = strenv(NETMASK_UPF_N6) |
                  .${nf}.multus.interfaces[2].gateway = strenv(GW_UPF_N6) |
                  .${nf}.multus.interfaces[2].routes = strenv(ROUTES_UPF_N6) |
                  .${nf}.multus.interfaces[2].enabled = \
                  (strenv(MULTUS_UPF_N6) == \"true\") |
                  .${nf}.multus.interfaces[2].type = \"macvlan\"
                " "$values_file"
                yq -i "
                  .${nf}.multus.interfaces[3].hostInterface = \
		  strenv(IF_NAME_UPF_N9) |
                  .${nf}.multus.interfaces[3].ipAdd = strenv(IP_UPF_N9) |
                  .${nf}.multus.interfaces[3].netmask = strenv(NETMASK_UPF_N9) |
                  .${nf}.multus.interfaces[3].gateway = strenv(GW_UPF_N9) |
                  .${nf}.multus.interfaces[3].routes = strenv(ROUTES_UPF_N9) |
                  .${nf}.multus.interfaces[3].enabled = \
                  (strenv(MULTUS_UPF_N9) == \"true\") |
                  .${nf}.multus.interfaces[3].type = \"macvlan\"
                " "$values_file"
                yq -i "
                  .${nf}.multus.interfaces[4].hostInterface = \
		  strenv(IF_NAME_UPF_SBI) |
                  .${nf}.multus.interfaces[4].ipAdd = strenv(IP_UPF_SBI) |
                  .${nf}.multus.interfaces[4].netmask = strenv(NETMASK_UPF_SBI) |
                  .${nf}.multus.interfaces[4].gateway = strenv(GW_UPF_SBI) |
                  .${nf}.multus.interfaces[4].enabled = \
		  (strenv(MULTUS_UPF_SBI) == \"true\") |
                  .${nf}.multus.interfaces[4].type = \"macvlan\"
                " "$values_file"
                ;;
            oai-traffic-server)
                yq -i "
                  .${nf}.multus.enabled = (strenv(MULTUS_TS) == \"true\") |
                  .${nf}.multus.interfaces[0].hostInterface = \
		  strenv(IF_NAME_TS) |
                  .${nf}.multus.interfaces[0].ipAdd = strenv(IP_TS) |
                  .${nf}.multus.interfaces[0].netmask = strenv(NETMASK_TS) |
                  .${nf}.multus.interfaces[0].defaultRoute = \
                  strenv(DEF_ROUTE_TS) |
                  .${nf}.multus.interfaces[0].enabled = \
                  (strenv(MULTUS_TS) == \"true\") |
                  .${nf}.multus.interfaces[0].type = \"macvlan\"
                " "$values_file"
                ;;
            oai-smf)
                yq -i "
                  .${nf}.multus.enabled = (strenv(MULTUS_SMF) == \"true\") |
                  .${nf}.multus.interfaces[0].hostInterface = \
		  strenv(IF_NAME_SMF_N4) |
                  .${nf}.multus.interfaces[0].ipAdd = strenv(IP_SMF_N4) |
                  .${nf}.multus.interfaces[0].netmask = strenv(NETMASK_SMF_N4) |
                  .${nf}.multus.interfaces[0].defaultRoute = \
                  strenv(DEF_ROUTE_SMF_N4) |
                  .${nf}.multus.interfaces[0].routes = strenv(ROUTES_SMF_N4) |
                  .${nf}.multus.interfaces[0].enabled = \
                  (strenv(MULTUS_SMF_N4) == \"true\") |
                  .${nf}.multus.interfaces[0].type = \"macvlan\"
                " "$values_file"
                yq -i "
                  .${nf}.multus.interfaces[1].hostInterface = \
		  strenv(IF_NAME_SMF_SBI) |
                  .${nf}.multus.interfaces[1].ipAdd = strenv(IP_SMF_SBI) |
                  .${nf}.multus.interfaces[1].netmask = strenv(NETMASK_SMF_SBI) |
                  .${nf}.multus.interfaces[1].gateway = strenv(GW_SMF_SBI) |
                  .${nf}.multus.interfaces[1].enabled = \
		  (strenv(MULTUS_SMF_SBI) == \"true\") |
                  .${nf}.multus.interfaces[1].type = \"macvlan\"
                " "$values_file"
                ;;
        esac

        # ---- DEBUG AFTER NF ----
        #echo "==== DEBUG $nf ===="
        #yq e ".${nf}" "$values_file"
        #echo "==================="
    done

    # ---- Diff values.yaml ----
    diff "$TMP/values.yaml-orig" "$values_file"

    #####################################
    # ---- config.yaml CONFIGURATION ----
    #####################################

    # NF interfaces
    yq -i "
      .nfs.amf.sbi.interface_name = strenv(NAME_AMF_SBI) |
      .nfs.amf.n2.interface_name = strenv(NAME_AMF_N2) |
      .nfs.smf.sbi.interface_name = strenv(NAME_SMF_SBI) |
      .nfs.smf.n4.interface_name = strenv(NAME_SMF_N4) |
      .nfs.upf.sbi.interface_name = strenv(NAME_UPF_SBI) |
      .nfs.upf.n3.interface_name = strenv(NAME_UPF_N3) |
      .nfs.upf.n4.interface_name = strenv(NAME_UPF_N4) |
      .nfs.upf.n6.interface_name = strenv(NAME_UPF_N6) |
      .nfs.upf.n9.interface_name = strenv(NAME_UPF_N9)
    " "$config_file"
    
    
    # SNSSAI slices
    yq -i "
      .snssais[0].sst = strenv(SLICE1_SST) |
      .snssais[0].sd = strenv(SLICE1_SD) |
      .snssais[1].sst = strenv(SLICE2_SST) |
      .snssais[1].sd = strenv(SLICE2_SD)
    " "$config_file"

    # AMF PLMN / TAC
    yq -i "
      .amf.served_guami_list[0].mcc = strenv(MCC) |
      .amf.served_guami_list[0].mnc = strenv(MNC) |
      .amf.plmn_support_list[0].mcc = strenv(MCC) |
      .amf.plmn_support_list[0].mnc = strenv(MNC) |
      .amf.plmn_support_list[0].tac = strenv(TAC)
    " "$config_file"

    # SMF DNN + QoS
    yq -i "
      .smf.smf_info.sNssaiSmfInfoList[0].dnnSmfInfoList[0].dnn = strenv(DNN0) |
      .smf.smf_info.sNssaiSmfInfoList[1].dnnSmfInfoList[0].dnn = strenv(DNN1) |
      .smf.local_subscription_infos[0].dnn = strenv(DNN0) |
      .smf.local_subscription_infos[0].qos_profile.5qi = strenv(SLICE1_5QI) |
      .smf.local_subscription_infos[0].qos_profile.session_ambr_ul = strenv(SLICE1_UPLINK) |
      .smf.local_subscription_infos[0].qos_profile.session_ambr_dl = strenv(SLICE1_DOWNLINK) |
      .smf.local_subscription_infos[1].dnn = strenv(DNN1) |
      .smf.local_subscription_infos[1].qos_profile.5qi = strenv(SLICE2_5QI) |
      .smf.local_subscription_infos[1].qos_profile.session_ambr_ul = strenv(SLICE2_UPLINK) |
      .smf.local_subscription_infos[1].qos_profile.session_ambr_dl = strenv(SLICE2_DOWNLINK)
    " "$config_file"

    # UPF DNN + SNAT and DNNs
    yq -i "
      .upf.upf_info.sNssaiUpfInfoList[0].dnnUpfInfoList[0].dnn = strenv(DNN0) |
      .upf.upf_info.sNssaiUpfInfoList[1].dnnUpfInfoList[0].dnn = strenv(DNN1) |
      .upf.support_features.enable_snat = strenv(ENABLE_SNAT) |
      .dnns[0].dnn = strenv(DNN0) |
      .dnns[0].pdu_session_type = strenv(DNN0_PDU_TYPE) |
      .dnns[1].dnn = strenv(DNN1) |
      .dnns[1].pdu_session_type = strenv(DNN1_PDU_TYPE) 
    " "$config_file"

    # if SD NSSAI field is set to "NULL", erase the sd line
    awk '!/EMPTY/' "$OAI5G_@MODE@"/config.yaml > /tmp/temp && mv /tmp/temp "$config_file"
    # ---- Diff config.yaml ----
    diff "$TMP/config.yaml-orig" "$config_file"

    ## SHOULD NO MORE BE USEFUL WITH THE LATEST CORRECTED CHARTS
    ### Fix Chart.yaml and run helm dependency update
    ##sed -i 's/version: v2.2.0.0/version: 2.2.0/g' "${OAI5G_ADVANCE}/Chart.yaml"

    ### Fix n4 nad name to prevent creation of n4 nad twice for upf and smf
    ##sed -i 's/name: {{ $.Release.Name }}-{{ .name }}/name: {{ $.Release.Name }}-{{ .name }}-upf/g' "${OAI5G_CORE}/oai-upf/templates/nad.yaml"
    ##sed -i 's/"name": "{{ $.Release.Name }}-{{ .name }}",/"name": "{{ $.Release.Name }}-{{ .name }}-upf",/g' "${OAI5G_CORE}/oai-upf/templates/nad.yaml"
    ##sed -i 's/"name": "{{ $.Release.Name }}-{{ .name }}",/"name": "{{ $.Release.Name }}-{{ .name }}-upf",/g' "${OAI5G_CORE}/oai-upf/templates/deployment.yaml"
    ##sed -i 's/name: {{ $.Release.Name }}-{{ .name }}/name: {{ $.Release.Name }}-{{ .name }}-smf/g' "${OAI5G_CORE}/oai-smf/templates/nad.yaml"
    ##sed -i 's/"name": "{{ $.Release.Name }}-{{ .name }}",/"name": "{{ $.Release.Name }}-{{ .name }}-smf",/g' "${OAI5G_CORE}/oai-smf/templates/nad.yaml"
    ##sed -i 's/"name": "{{ $.Release.Name }}-{{ .name }}",/"name": "{{ $.Release.Name }}-{{ .name }}-smf",/g' "${OAI5G_CORE}/oai-smf/templates/deployment.yaml"

    # Run helm dependency update
    cd "${OAI5G_ADVANCE}"
    echo "run helm dependency update"
    helm dependency update
}


#################################################################################

configure-mysql() {

    DIR_ORIG_CHART="${OAI5G_CORE}/mysql/initialization"
    DIR_PATCHED_CHART="${PREFIX_DEMO}/oai5g-rru/patch-mysql"

    echo "configure-mysql: mysql database already patched by configure-demo-oai.sh script, just copy it"
    echo "cp ${DIR_PATCHED_CHART}/oai_db-basic.sql ${DIR_ORIG_CHART}/"
    cp ${DIR_PATCHED_CHART}/oai_db-basic.sql ${DIR_ORIG_CHART}/
    # if SD NSSAI field is set to "NULL", replace it by "FFFFFF" in the mysql database
    sed -i 's/EMPTY/FFFFFF/g' $DIR_ORIG_CHART/oai_db-basic.sql
}

#################################################################################



load_rru_env() {
    local file="${PREFIX_DEMO}/oai5g-rru/rru/$1.env"
    [[ -f "$file" ]] || return 1
    set -a
    source "$file"
    set +a
}


apply-gnb-values-yq() {

    values_file="$1"
    yq_overlay_file="$2"

    [ -f "$values_file" ] || {
        echo "ERROR: values file not found: $values_file"
        exit 1
    }

    [ -f "$yq_overlay_file" ] || {
        echo "ERROR: yq overlay file not found: $yq_overlay_file"
        exit 1
    }

    echo "Applying yq overlays from $yq_overlay_file to $values_file"

    yq eval -i --style=double "$(cat "$yq_overlay_file")" "$values_file"

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
' "$values_file"
    
    # Validate new values.yaml configuration
    yq eval '.' "$values_file" >/dev/null || {
        echo "ERROR: generated YAML is invalid: $values_file"
        exit 1
    }
    echo "OK: $values_file updated successfully"
}


render_nf_ifs() {
    local nf="$1"
    local base="${PREFIX_DEMO}/oai5g-rru/demo_charts/values/nf-ifs"

    if [[ "$nf" == "oai-du" && "$GNB_MODE" == "cucpup" ]]; then
        envsubst < "${base}/oai-du-cucpup.yaml"
    elif [[ "$nf" == "oai-du-fhi-72" && "$GNB_MODE" == "cucpup" ]]; then
        envsubst < "${base}/oai-du-fhi-72-cucpup.yaml"
    else
        envsubst < "${base}/${nf}.yaml"
    fi
}


configure-gnb() {
    echo "configure-gnb: gNB on node $NODE_GNB with RRU $RRU and logs is $LOGS"

    ORIG_GNB_TEMPLATES="${OAI5G_RAN}/oai-gnb/templates"
    ORIG_DU_TEMPLATES="${OAI5G_RAN}/oai-du/templates"
    NEW_TEMPLATES="${PREFIX_DEMO}/oai5g-rru/demo_charts/templates"
  
    # First load RU specific parameters
    load_rru_env "$RRU" || {
	echo "Unknown RRU: $RRU"
	exit 1
    }

    for nf in oai-gnb oai-gnb-fhi-72 oai-du oai-du-fhi-72 oai-cu oai-cu-cp oai-cu-up; do
	VALUES="${OAI5G_RAN}/${nf}/values.yaml"
	    
	if [[ ! -f "$VALUES" ]]; then
	    echo "Skipping $nf: file not found"
	    continue
	fi	
	cp "$VALUES" "${OAI5G_RAN}/${nf}/values.yaml.orig"
	    
	# First remove multus interfaces
	yq eval -i 'del(.multus.interfaces)' "$VALUES"
	
	# Inject multus interfaces
	TMP_IFS="$(mktemp)"
	render_nf_ifs "$nf" > "${TMP_IFS}"
	if [[ ! -s "${TMP_IFS}" ]]; then
	    echo "ERROR: empty NF_IFS for $nf"
	    rm -f "${TMP_IFS}"
	    continue
	fi
	yq eval -i "
          .multus.enabled = true |
          .multus.interfaces = load(\"$TMP_IFS\")
        " "$VALUES"
	rm -f "$TMP_IFS"
	
	# Update remaining parameters
	apply-gnb-values-yq "${VALUES}" "${PREFIX_DEMO}/oai5g-rru/demo_charts/values/${nf}.yq"
	##diff -u <(yq eval -P '.' ${OAI5G_RAN}/${nf}/values.yaml.orig) <(yq eval -P '.' ${VALUES})
    done

    # Update config.yaml charts
    if [[ ${GNB_MODE} = 'monolithic' ]]; then
	gnb_type="gnb"
	if [[ "$RRU_TYPE" == "benetel" ]]; then
	    nf="oai-gnb-fhi-72"
	else
	    nf="oai-gnb"
	fi
    else
	gnb_type="du"
	if [[ "${RRU_TYPE}" == "benetel" ]]; then
	    nf="oai-du-fhi-72"
	else
	    nf="oai-du"
	fi
    fi
    CONFIG_RRU="${PREFIX_DEMO}/oai5g-rru/rru/${gnb_type}-config-${RRU_TYPE}.yaml"
    CONFIG="${OAI5G_RAN}/${nf}/config.yaml"
    cp "$CONFIG" "${OAI5G_RAN}/${nf}/config.yaml.orig"
    cp "${CONFIG_RRU}" "$CONFIG"
    ##diff -u <(yq eval -P '.' ${OAI5G_RAN}/${nf}/config.yaml.orig) <(yq eval -P '.' ${CONFIG})

    # Update deployment.yaml and nad.yaml templates
    cp -f "${NEW_TEMPLATES}/oai-gnb/nad.yaml" "${ORIG_GNB_TEMPLATES}"
    cp -f "${NEW_TEMPLATES}/oai-du/nad.yaml" "${ORIG_DU_TEMPLATES}"
    # fix also this typo in the du deployment template 
    sed -i 's/oai-cu.count/oai-du.count/g' "${ORIG_DU_TEMPLATES}/deployment.yaml"

    # Fix deployment charts in the case of AW2S RUs as Eurecom no more support AW2S...
    if [[ "${RRU_TYPE}" == "aw2s" ]]; then
	for nf in oai-gnb oai-du; do
	    cp "${PREFIX_DEMO}/oai5g-rru/rru/${nf}-deployment-aw2s.yaml" "${OAI5G_RAN}/${nf}/templates/deployment.yaml"
	done
	# except for oai-cu-up
	for nf in oai-cu oai-cu-cp; do
	    DEPLOYMENT="${OAI5G_RAN}/${nf}/templates/deployment.yaml"
	    sed -i 's|/opt/oai-gnb/etc|/opt/oai-gnb-aw2s/etc|' "$DEPLOYMENT"
	done
    fi
    
}



#################################################################################



configure-nr-ue() {
    ORIG_VALUES="${OAI5G_RAN}/oai-nr-ue/values.yaml"
    TMP_VALUES="$TMP/oai-nr-ue_values.yaml-orig"
    ORIG_TEMPLATES="${OAI5G_RAN}/oai-nr-ue/templates"
    NEW_TEMPLATES="${PREFIX_DEMO}/oai5g-rru/demo_charts/templates/oai-nr-ue"

    cp "$ORIG_VALUES" "${TMP_VALUES}"

    # Insert the multus block BEFORE the config block
    # Keep indentation and comments intact
    awk -v multus="multus:
  enabled: ${MULTUS_NRUE}
  interfaces:
    - name: \"net1\"
      enabled: ${MULTUS_NRUE}
      hostInterface: \"${IF_NAME_NRUE}\"
      ipAdd: \"$IP_NRUE\"
      netmask: \"${NETMASK_NRUE}\"
      defaultGateway: \"${DEFAULT_GW_NRUE}\"
      type: macvlan
      mode: \"bridge\"
  " '
    {
        if ($0 ~ /^config:/ && !inserted) {
            printf "%s\n", multus
            inserted=1
        }
        print
    }
    ' "${ORIG_VALUES}" > "${ORIG_VALUES}.tmp" && mv "${ORIG_VALUES}.tmp" "${ORIG_VALUES}"

    # Then update the variable fields
    yq eval -i '
      .nfimage.repository = strenv(NRUE_REPO) |
      .nfimage.version = strenv(NRUE_TAG) |
      .config.fullImsi = strenv(RFSIM_IMSI) |
      .config.fullKey  = strenv(FULL_KEY) |
      .config.opc      = strenv(OPC) |
      .config.dnn      = strenv(DNN0) |
      .config.sst      = strenv(SLICE1_SST) |
      .config.sd       = ("0x" + strenv(SLICE1_SD)) |
      .config.useAdditionalOptions = strenv(ADD_OPTIONS_NRUE) |
      .includeTcpDumpContainer = (strenv(LOGS) | test("true")) |
      .resources.define = (strenv(QOS_NRUE) | test("true")) |
      .nodeName         = strenv(NODE_NRUE)
    ' "${ORIG_VALUES}"

    sed -i 's/0xEMPTY/16777215/g' "${ORIG_VALUES}"
    ##diff "${TMP_VALUES}" "${ORIG_VALUES}"

    # Update deployment.yaml and nad.yaml templates
    cp -f "${NEW_TEMPLATES}/deployment.yaml" "${ORIG_TEMPLATES}"
    cp -f "${NEW_TEMPLATES}/nad.yaml" "${ORIG_TEMPLATES}"
}


#################################################################################

configure-nr-ue2() {

    DIR="${OAI5G_RAN}/oai-nr-ue2"
    ORIG_VALUES="${DIR}/values.yaml"

    # First remove oai-nr-ue2 chart if there and create a new one based on oai-nr-ue chart
    rm -rf "$DIR"
    cp -pr "${OAI5G_RAN}/oai-nr-ue" "$DIR"
    find "$DIR" -type f -exec sed -i 's/oai-nr-ue/oai-nr-ue2/g' {} +
    sed -i 's/oai-nr-ue2\/bin/oai-nr-ue\/bin/g' "$DIR/templates/deployment.yaml"
    sed -i 's/oai-nr-ue2\/etc/oai-nr-ue\/etc/g' "$DIR/templates/deployment.yaml"
    
    # Then update the variable fields
    yq eval -i '
      .nfimage.repository = strenv(NRUE_REPO) |
      .nfimage.version = strenv(NRUE_TAG) |
      .multus.ipadd    = strenv(IP_NRUE2) |
      .config.fullImsi = strenv(RFSIM_IMSI_UE2) |
      .config.fullKey  = strenv(FULL_KEY) |
      .config.opc      = strenv(OPC) |
      .config.dnn      = strenv(DNN1) |
      .config.sst      = strenv(SLICE2_SST) |
      .config.sd       = ("0x" + strenv(SLICE2_SD)) |
      .config.useAdditionalOptions = strenv(ADD_OPTIONS_NRUE) |
      .includeTcpDumpContainer = (strenv(LOGS) | test("true")) |
      .resources.define = (strenv(QOS_NRUE) | test("true"))
    ' "$ORIG_VALUES"

    sed -i 's/0xEMPTY/16777215/g' "${ORIG_VALUES}"
    ##cat "${ORIG_VALUES}"
}

#################################################################################

configure-nr-ue3() {

    DIR="${OAI5G_RAN}/oai-nr-ue3"
    ORIG_VALUES="${DIR}/values.yaml"

    # First remove oai-nr-ue3 chart if there and create a new one based on oai-nr-ue chart
    rm -rf "$DIR"
    cp -pr "${OAI5G_RAN}/oai-nr-ue" "$DIR"
    find "$DIR" -type f -exec sed -i 's/oai-nr-ue/oai-nr-ue3/g' {} +
    sed -i 's/oai-nr-ue3\/bin/oai-nr-ue\/bin/g' "$DIR/templates/deployment.yaml"
    sed -i 's/oai-nr-ue3\/etc/oai-nr-ue\/etc/g' "$DIR/templates/deployment.yaml"
    
    # Then update the variable fields
    yq eval -i '
      .nfimage.repository = strenv(NRUE_REPO) |
      .nfimage.version = strenv(NRUE_TAG) |
      .multus.ipadd    = strenv(IP_NRUE3) |
      .config.fullImsi = strenv(RFSIM_IMSI_UE3) |
      .config.fullKey  = strenv(FULL_KEY) |
      .config.opc      = strenv(OPC) |
      .config.dnn      = strenv(DNN1) |
      .config.sst      = strenv(SLICE2_SST) |
      .config.sd       = ("0x" + strenv(SLICE2_SD)) |
      .config.useAdditionalOptions = strenv(ADD_OPTIONS_NRUE) |
      .includeTcpDumpContainer = (strenv(LOGS) | test("true")) |
      .resources.define = (strenv(QOS_NRUE) | test("true"))
    ' "${ORIG_VALUES}"

    sed -i 's/0xEMPTY/16777215/g' "${ORIG_VALUES}"
    ##cat "${ORIG_VALUES}"
}


#################################################################################

configure-flexric() {

    DIR="${OAI5G_RAN}/oai-flexric"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="$TMP/oai-flexric-values.sed"
    echo "configure-flexric: ${ORIG_CHART} configuration"
    cat > "${SED_FILE}" <<EOF
s|@FLEXRIC_REPO@|$FLEXRIC_REPO|
s|@FLEXRIC_TAG@|$FLEXRIC_TAG|
s|@FLEXRIC_PULL_POLICY@|$FLEXRIC_PULL_POLICY|
EOF
    cp "$ORIG_CHART" "$TMP"/oai-flexric_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < "$TMP"/oai-flexric_values.yaml-orig > "${ORIG_CHART}"
    # if SD NSSAI field is set to "NULL", replace it by "16777215"
    sed -i 's/0xEMPTY/16777215/g' "$ORIG_CHART"
    diff "$TMP"/oai-flexric_values.yaml-orig "${ORIG_CHART}"
}


#################################################################################

configure-all() {
    echo "configure-all: Applying SophiaNode patches to OAI5G charts located on \"$PREFIX_DEMO/oai-cn5g-fed\""
    echo -e "\t with oai-upf running on \"${NODE_AMF_UPF}\""
    echo -e "\t with oai-gnb running on \"${NODE_GNB}\""
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
    echo "cd ${OAI5G_@MODE@}"
    cd "${OAI5G_@MODE@}" || { echo "Error: Failed to change directory"; exit 1; }

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

    echo "Running start-flexric() on namespace: $NS, NODE_GNB=${NODE_GNB}"
    echo "cd ${OAI5G_RAN}"
    cd "${OAI5G_RAN}"

    echo "helm -n $NS install oai-flexric oai-flexric/" 
    helm -n $NS install oai-flexric oai-flexric/

    echo "Wait until oai-flexric pod is READY"
    kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-flexric
}

#################################################################################


start-gnb() {
    echo "Running gNB on $NS namespace with GNB_MODE=${GNB_MODE}, NODE_GNB=${NODE_GNB} and rru=$RRU"

    echo "cd ${OAI5G_RAN}"
    cd "${OAI5G_RAN}"

    if [[ ${GNB_MODE} = 'monolithic' ]]; then
	echo "helm -n $NS install oai-gnb oai-gnb/"
	helm -n $NS install oai-gnb oai-gnb/
	echo "Wait until the gNB pod is READY"
	kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-gnb
    elif [[ ${GNB_MODE} = 'cudu' ]]; then
	echo "helm -n $NS install oai-cu oai-cu/"
	helm -n $NS install oai-cu oai-cu/

	echo "sleep 5s"; sleep 5
	echo "kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu"
	kubectl -n $NS wait pod --for=condition=Ready -l app.kubernetes.io/instance=oai-cu
	echo "helm install -n $NS oai-du oai-du/"
	helm install -n $NS oai-du oai-du/
    else
	# ${GNB_MODE} = 'cucpup'
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

    echo "Running start-nr-ue() on namespace: $NS, NODE_GNB=${NODE_GNB}"
    echo "cd ${OAI5G_RAN}"
    cd "${OAI5G_RAN}"

    if [[ "${MULTUS_NRUE}" == "true" ]]; then
	case "${GNB_MODE}" in
	    'monolithic')
		GNB_IP="${IP_GNB_N3}" ;;
	    'cudu')
		GNB_IP="${IP_DU_F1}" ;;
	    'cucpup')
		GNB_IP="${IP_DU_F1U}" ;;
	esac
    else
	echo "retrieve dynamically gNB/DU IP"
	if [[ ${GNB_MODE} == 'monolithic' ]]; then
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

    echo "Running start-nr-ue2() on namespace: $NS, NODE_GNB=${NODE_GNB}"
    echo "cd ${OAI5G_RAN}"
    cd "${OAI5G_RAN}"

    if [[ "${MULTUS_NRUE}" == "true" ]]; then
	case "${GNB_MODE}" in
	    'monolithic')
		GNB_IP="${IP_GNB_N3}" ;;
	    'cudu')
		GNB_IP="${IP_DU_F1}" ;;
	    'cucpup')
		GNB_IP="${IP_DU_F1U}" ;;
	esac
    else
	echo "retrieve dynamically gNB/DU IP"
	if [[ ${GNB_MODE} == 'monolithic' ]]; then
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

    echo "Running start-nr-ue3() on namespace: $NS, NODE_GNB=${NODE_GNB}"
    echo "cd ${OAI5G_RAN}"
    cd "${OAI5G_RAN}"

    if [[ "${MULTUS_NRUE}" == "true" ]]; then
	case "${GNB_MODE}" in
	    'monolithic')
		GNB_IP="${IP_GNB_N3}" ;;
	    'cudu')
		GNB_IP="${IP_DU_F1}" ;;
	    'cucpup')
		GNB_IP="${IP_DU_F1U}" ;;
	esac
    else
	echo "retrieve dynamically gNB/DU IP"
	if [[ ${GNB_MODE} == 'monolithic' ]]; then
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
    if [[ ${GNB_MODE} = 'monolithic' ]]; then
	echo "helm -n $NS uninstall oai-gnb"
	helm -n $NS uninstall oai-gnb
    else
	echo "helm -n $NS uninstall oai-du"
	helm -n $NS uninstall oai-du
	if [[ ${GNB_MODE} = 'cudu' ]]; then
	    echo "helm -n $NS uninstall oai-cu"
	    helm -n $NS uninstall oai-cu
	else
	    # ${GNB_MODE} = 'cucpup'
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
	echo "First retrieve all pcap and logs files in ${dir_stats} and compressed it"
	mkdir -p "${dir_stats}"
	echo "cleanup ${dir_stats} before including new logs/pcap files"
	cd "${dir_stats}"; rm -f *.pcap *.tgz *.logs *stats* *.conf
	if [[ "$PCAP" = "true" ]]; then
	    get-all-pcap "${dir_stats}"
	fi
	get-all-logs "${dir_stats}"
	cd "$TMP"; dirname=$(basename "${dir_stats}")
	echo tar cfz "$dirname".tgz "$dirname"
	tar cfz "$dirname".tgz "$dirname"
    fi

    res=$(helm -n $NS ls | wc -l)
    if test "$res" -gt 1; then
        echo "Remove all 5G OAI pods"
	if [[ "${RUN_MODE}" != "gnb-only" ]]; then
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
    tar -C "${PREFIX_DEMO}" -cf "$prefix"/charts.tar charts

    echo "get-all-logs: saving demo-oai.sh script"
    cp "${PREFIX_DEMO}"/demo-oai.sh "$prefix"/

    if [[ -f "${PREFIX_DEMO}"/prepare-demo-oai.sh ]]; then
        echo "get-all-logs: saving prepare-demo-oai.sh script"
    	cp "${PREFIX_DEMO}/prepare-demo-oai.sh" "$prefix"/
    fi

    AMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    AMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-amf ${AMF_POD_NAME} running with IP ${AMF_eth0_IP}"
    kubectl --namespace $NS -c amf logs "${AMF_POD_NAME}" > "$prefix"/amf-"$DATE".logs

    AUSF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    AUSF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-ausf ${AUSF_POD_NAME} running with IP ${AUSF_eth0_IP}"
    kubectl --namespace $NS -c ausf logs "${AUSF_POD_NAME}" > "$prefix"/ausf-"$DATE".logs

    NRF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    NRF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-nrf ${NRF_POD_NAME} running with IP ${NRF_eth0_IP}"
    kubectl --namespace $NS -c nrf logs "${NRF_POD_NAME}" > "$prefix"/nrf-"$DATE".logs

    SMF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    SMF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-smf ${SMF_POD_NAME} running with IP ${SMF_eth0_IP}"
    kubectl --namespace $NS -c smf logs "${SMF_POD_NAME}" > "$prefix"/smf-"$DATE".logs

    UPF_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-upf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UPF_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-upf,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-upf ${UPF_POD_NAME} running with IP ${UPF_eth0_IP}"
    kubectl --namespace $NS -c upf logs "${UPF_POD_NAME}" > "$prefix"/upf-"$DATE".logs

    UDM_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UDM_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-udm ${UDM_POD_NAME} running with IP ${UDM_eth0_IP}"
    kubectl --namespace $NS -c udm logs "${UDM_POD_NAME}" > "$prefix"/udm-"$DATE".logs
    
    UDR_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[0].metadata.name}")
    UDR_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-5g-@mode@" -o jsonpath="{.items[*].status.podIP}")
    echo -e "\t - Retrieving logs for oai-udr ${UDR_POD_NAME} running with IP ${UDR_eth0_IP}"
    kubectl --namespace $NS -c udr logs "${UDR_POD_NAME}" > "$prefix"/udr-"$DATE".logs

    if [[ ${GNB_MODE} = 'monolithic' ]]; then
	GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
	GNB_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-gnb ${GNB_POD_NAME} running with IP ${GNB_eth0_IP}"
	kubectl --namespace $NS -c gnb logs "${GNB_POD_NAME}" > "$prefix"/gnb-"$DATE".logs
	echo "Retrieve gnb config from the pod"
	kubectl -c gnb cp $NS/"GNB_POD_NAME":/tmp/gnb.conf "$prefix"/gnb.conf || true
	echo "Retrieve nrL1_stats.log, nrMAC_stats.log and nrRRC_stats.log from gnb pod"
	kubectl -c gnb cp $NS/"${GNB_POD_NAME}":nrL1_stats.log "$prefix"/nrL1_stats.log"$DATE" || true
	kubectl -c gnb cp $NS/"${GNB_POD_NAME}":nrMAC_stats.log "$prefix"/nrMAC_stats.log"$DATE" || true
	kubectl -c gnb cp $NS/"${GNB_POD_NAME}":nrRRC_stats.log "$prefix"/nrRRC_stats.log"$DATE" || true
    elif [[ ${GNB_MODE} = 'cudu' ]]; then
	CU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[0].metadata.name}")
	CU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-cu ${CU_POD_NAME} running with IP $CU_eth0_IP"
	kubectl --namespace $NS -c oai-cu logs "${CU_POD_NAME}" > "$prefix"/cu-"$DATE".logs
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	kubectl -c du cp $NS/"${DU_POD_NAME}":nrL1_stats.log "$prefix"/nrL1_stats.log"$DATE" || true
	kubectl -c du cp $NS/"${DU_POD_NAME}":nrMAC_stats.log "$prefix"/nrMAC_stats.log"$DATE" || true
	kubectl -c oai-cu cp $NS/"${CU_POD_NAME}":nrRRC_stats.log "$prefix"/nrRRC_stats.log"$DATE" || true
	DU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-du ${DU_POD_NAME} running with IP $DU_eth0_IP"
	kubectl --namespace $NS -c du logs "${DU_POD_NAME}" > "$prefix"/du-"$DATE".logs
	echo "Retrieve cu/du configs from the pods"
	kubectl -c oai-cu cp $NS/"${CU_POD_NAME}":/tmp/cu.conf "$prefix"/cu.conf || true
	kubectl -c du cp $NS/"${DU_POD_NAME}":/tmp/du.conf "$prefix"/du.conf || true
    else
	# ${GNB_MODE} = 'cucpup'
	CUCP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[0].metadata.name}")
	CUCP_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oaicucp ${CUCP_POD_NAME} running with IP $CUCP_eth0_IP"
	kubectl --namespace $NS -c oaicucp logs "${CUCP_POD_NAME}" > "$prefix"/cucp-"$DATE".logs
	CUUP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[0].metadata.name}")
	CUUP_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oaicuup ${CUUP_POD_NAME} running with IP $CUUP_eth0_IP"
	kubectl --namespace $NS -c oaicuup logs "${CUUP_POD_NAME}" > "$prefix"/cuup-"$DATE".logs
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	kubectl -c du cp $NS/"${DU_POD_NAME}":nrL1_stats.log "$prefix"/nrL1_stats.log"$DATE" || true
	kubectl -c du cp $NS/"${DU_POD_NAME}":nrMAC_stats.log "$prefix"/nrMAC_stats.log"$DATE" || true
	kubectl -c oaicucp cp $NS/"${CUCP_POD_NAME}":nrRRC_stats.log "$prefix"/nrRRC_stats.log"$DATE" || true
	DU_eth0_IP=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[*].status.podIP}")
	echo -e "\t - Retrieving logs for oai-du ${DU_POD_NAME} running with IP $DU_eth0_IP"
	kubectl --namespace $NS -c du logs "${DU_POD_NAME}" > "$prefix"/du-"$DATE".logs
	echo "Retrieve cucp/cuup/du configs from the pods"
	kubectl -c oaicucp cp $NS/"${CUCP_POD_NAME}":/tmp/cucp.conf "$prefix"/cucp.conf || true
	kubectl -c oaicuup cp $NS/"${CUUP_POD_NAME}":/tmp/cuup.conf "$prefix"/cuup.conf || true
	kubectl -c du cp $NS/"${DU_POD_NAME}":/tmp/du.conf "$prefix"/du.conf || true
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

    if [[ ${GNB_MODE} = 'monolithic' ]]; then
	GNB_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
	echo "Retrieve OAI5G gnb pcap file from the oai-gnb pod on ns $NS"
	echo "kubectl -c tcpdump -n $NS exec -i ${GNB_POD_NAME} -- /bin/tar cfz gnb-pcap.tgz -C tmp pcap"
	kubectl -c tcpdump -n $NS exec -i "${GNB_POD_NAME}" -- /bin/tar cfz gnb-pcap.tgz -C tmp pcap || true
	echo "kubectl -c tcpdump cp $NS/${GNB_POD_NAME}:gnb-pcap.tgz $prefix/gnb-pcap-$DATE.tgz"
	kubectl -c tcpdump cp $NS/"${GNB_POD_NAME}":gnb-pcap.tgz "$prefix"/gnb-pcap-"$DATE".tgz || true
    else
	DU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-du" -o jsonpath="{.items[0].metadata.name}")
	echo "Retrieve OAI5G du pcap file from the oai-du pod on ns $NS"
	echo "kubectl -c tcpdump -n $NS exec -i ${DU_POD_NAME} -- /bin/tar cfz du-pcap.tgz -C tmp pcap"
	kubectl -c tcpdump -n $NS exec -i "${DU_POD_NAME}" -- /bin/tar cfz du-pcap.tgz -C tmp pcap || true
	echo "kubectl -c tcpdump cp $NS/${DU_POD_NAME}:du-pcap.tgz $prefix/du-pcap-$DATE.tgz"
	kubectl -c tcpdump cp $NS/"${GNB_POD_NAME}":du-pcap.tgz "$prefix"/du-pcap-"$DATE".tgz || true
	if [[ ${GNB_MODE} = 'cudu' ]]; then
	    CU_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu" -o jsonpath="{.items[0].metadata.name}")
	    echo "Retrieve OAI5G cu pcap file from the oai-cu pod on ns $NS"
	    echo "kubectl -c tcpdump -n $NS exec -i ${CU_POD_NAME} -- /bin/tar cfz cu-pcap.tgz -C tmp pcap"
	    kubectl -c tcpdump -n $NS exec -i "${CU_POD_NAME}" -- /bin/tar cfz cu-pcap.tgz -C tmp pcap || true
	    echo "kubectl -c tcpdump cp $NS/${CU_POD_NAME}:cu-pcap.tgz $prefix/cu-pcap-$DATE.tgz"
	    kubectl -c tcpdump cp $NS/"${CU_POD_NAME}":cu-pcap.tgz "$prefix"/cu-pcap-"$DATE".tgz || true
	else
	    CUCP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-cp" -o jsonpath="{.items[0].metadata.name}")
	    echo "Retrieve OAI5G cucp pcap file from the oai-cu-cp pod on ns $NS"
	    echo "kubectl -c tcpdump -n $NS exec -i ${CUCP_POD_NAME} -- /bin/tar cfz cucp-pcap.tgz -C tmp pcap"
	    kubectl -c tcpdump -n $NS exec -i "${CUCP_POD_NAME}" -- /bin/tar cfz cucp-pcap.tgz -C tmp pcap || true
	    echo "kubectl -c tcpdump cp $NS/${CUCP_POD_NAME}:cucp-pcap.tgz $prefix/cucp-pcap-$DATE.tgz"
	    kubectl -c tcpdump cp $NS/"${CUCP_POD_NAME}":cucp-pcap.tgz "$prefix"/cucp-pcap-"$DATE".tgz || true
	    CUUP_POD_NAME=$(kubectl get pods --namespace $NS -l "app.kubernetes.io/instance=oai-cu-up" -o jsonpath="{.items[0].metadata.name}")
	    echo "Retrieve OAI5G cuup pcap file from the oai-cu-up pod on ns $NS"
	    echo "kubectl -c tcpdump -n $NS exec -i ${CUUP_POD_NAME} -- /bin/tar cfz cuup-pcap.tgz -C tmp pcap"
	    kubectl -c tcpdump -n $NS exec -i "${CUUP_POD_NAME}" -- /bin/tar cfz cuup-pcap.tgz -C tmp pcap || true
	    echo "kubectl -c tcpdump cp $NS/${CUUP_POD_NAME}:cuup-pcap.tgz $prefix/cuup-pcap-$DATE.tgz"
	    kubectl -c tcpdump cp $NS/"${CUUP_POD_NAME}":cuup-pcap.tgz "$prefix"/cuup-pcap-"$DATE".tgz || true
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

