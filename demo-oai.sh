#!/bin/bash


##########################################################################
# Following parameters automatically set by configure-demo-oai.sh script
# do not change them here !
DEF_NS= # k8s namespace
DEF_NODE_AMF_SPGWU= # node in wich run amf and spgwu pods
DEF_NODE_GNB= # node in which gnb pod runs
DEF_RRU= # in ['b210', 'n300', 'n320', 'jaguar', 'panther', 'rfsim']
DEF_GNB_ONLY= # boolean if pcap are generated on pods
DEF_PCAP= # boolean if pcap are generated on pods
##########################################################################

PREFIX_STATS="/tmp/oai5g-stats"

# IP local Pod addresses
P100="192.168.100"
IP_AMF_N2="$P100.241"
IP_UPF_N3="$P100.242" # Nota: only used for CN configuration
IP_GNB_N2N3="$P100.243"
IP_GNB_SFP1="192.168.10.132"
IP_GNB_SFP2="192.168.20.132"
IP_AW2S="$IP_GNB_N2N3" # in R2lab setup, single interface to join AW2S device and AMF/SPGWU (N2/N3)
IP_NRUE="$P100.244"

# Netmask definitions
NETMASK_GNB_N2N3="24"
NETMASK_GNB_RU1="24"
NETMASK_GNB_RU2="24"
NETMASK_NRUE="24"

#MTU definitions
MTU_N3XX="9000"

# IP addresses of RRU devices
# USRP N3XX devices
# do not specify mgmt_address, this makes USRP not found !
#ADDRS_N300="addr=192.168.10.129,second_addr=192.168.20.129,mgmt_addr=192.168.3.151"
#ADDRS_N320="addr=192.168.10.130,second_addr=192.168.20.130,mgmt_addr=192.168.3.152"
ADDRS_N300="addr=192.168.10.129,second_addr=192.168.20.129"
ADDRS_N320="addr=192.168.10.130,second_addr=192.168.20.130"
# AW2S devices
ADDR_JAGUAR="$P100.48" # for eth1
ADDR_PANTHER="$P100.51" # .51 for eth2

# Interfaces names of VLANs in sopnode servers
#IF_NAME_VLAN100="p4-net"
IF_NAME_VLAN100="eth5"
IF_NAME_VLAN10="p4-net-10"
IF_NAME_VLAN20="p4-net-20"

# N2/N3 and RRU Interfaces definitions
IF_NAME_AMF_N2_SPGWU_N3="$IF_NAME_VLAN100" # Nota: only used for CN configuration
IF_NAME_GNB_N2="$IF_NAME_VLAN100"
IF_NAME_GNB_N3="$IF_NAME_VLAN100"
IF_NAME_GNB_N2N3="$IF_NAME_VLAN100"
IF_NAME_GNB_AW2S="$IF_NAME_VLAN100"
IF_NAME_N3XX_1="$IF_NAME_VLAN10"
IF_NAME_N3XX_2="$IF_NAME_VLAN20"
IF_NAME_NRUE="$IF_NAME_VLAN100"

# IN CASE OF EXTERNAL CORE NETWORK USAGE (i.e., DEF_GNB_ONLY IS TRUE), CONFIGURE THE FOLLOWING PARAMETERS BELOW:
if [[ $DEF_GNB_ONLY == "True" ]]; then
    AMF_IP_ADDR="172.22.10.6" # external AMF IP address, e.g., "172.22.10.6"
    ROUTE_GNB_TO_EXTCN="172.22.10.0/24" # route to reach amf for multus.yaml chart, e.g., "172.22.10.0/24"
    IP_GNB_N2N3="10.0.20.243" # local IP to reach AMF/UPF, e.g., "10.0.20.243"
    GW_GNB_TO_EXTCN="10.0.20.1" # gw for multus.yaml chart, e.g., "10.0.20.1"
    IF_NAME_GNB_N2N3="ran" # Right Host network interface to reach AMF/UPF
fi

# gNB conf file for RRU devices
#CONF_JAGUAR="jaguar_panther2x2_50MHz.conf"
#CONF_JAGUAR="panther4x4_20MHz.conf"
#CONF_JAGUAR="aw2s4x4_50MHz.conf"
CONF_JAGUAR="gnb.sa.band78.51prb.aw2s.ddsuu.conf"
CONF_PANTHER="panther4x4_20MHz.conf"
#CONF_B210="gnb.band78.51PRB.usrpb210.conf" # without -E
CONF_B210="gnb.sa.band78.fr1.51PRB.usrpb210-new.conf" # this one needs -E as an additional option
#CONF_B210="gnb.sa.band78.fr1.51PRB.usrpb210-latest.conf"
#CONF_B210="gnb.sa.band78.fr1.51PRB.usrpb210-orig.conf" # this one without -E as an additional option
CONF_N3XX="gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf"
CONF_RFSIM="gnb.sa.band78.106prb.rfsim.2x2.conf" #this one works
#CONF_RFSIM="gnb.sa.band78.fr1.51PRB.rfsim.conf"



OAI5G_CHARTS="$HOME"/oai-cn5g-fed/charts
OAI5G_CORE="$OAI5G_CHARTS"/oai-5g-core
OAI5G_BASIC="$OAI5G_CORE"/oai-5g-basic
OAI5G_RAN="$OAI5G_CHARTS"/oai-5g-ran
OAI5G_AMF="$OAI5G_CORE"/oai-amf
OAI5G_AUSF="$OAI5G_CORE"/oai-ausf
OAI5G_SMF="$OAI5G_CORE"/oai-smf
OAI5G_SPGWU="$OAI5G_CORE"/oai-spgwu-tiny
OAI5G_NRUE="$OAI5G_CORE"/oai-nr-ue

# Following variables are set by the configure-demo.sh script
# Do not modify them here !
#
MCC="@DEF_MCC@"
MNC="@DEF_MNC@"
DNN="@DEF_DNN@"
TAC="@DEF_TAC@"
SST="@DEF_SST@"
FULL_KEY="@DEF_FULL_KEY@"
OPC="@DEF_OPC@"
RFSIM_IMSI="@DEF_RFSIM_IMSI@"
#


####
#    Following variables used to select repo and tag for OAI5G docker images
#
OAISA_REPO="docker.io/oaisoftwarealliance"

# OAI5G CN docker images
CN_TAG="develop"

NRF_REPO="${OAISA_REPO}/oai-nrf"
NRF_TAG="${CN_TAG}"
UDR_REPO="${OAISA_REPO}/oai-udr"
UDR_TAG="${CN_TAG}"
UDM_REPO="${OAISA_REPO}/oai-udm"
UDM_TAG="${CN_TAG}"
AUSF_REPO="${OAISA_REPO}/oai-ausf"
AUSF_TAG="${CN_TAG}"
AMF_REPO="${OAISA_REPO}/oai-amf"
AMF_TAG="${CN_TAG}"
#AMF_REPO="${OAISA_REPO}/oai-amf"
#AMF_REPO="docker.io/rohankharade/oai-amf"
#AMF_TAG="service_accept"
SPGWU_REPO="docker.io/r2labuser/oai-spgwu-tiny"
SPGWU_TAG="rocky-test90"
#SPGWU_REPO="${OAISA_REPO}/oai-spgwu-tiny"
#SPGWU_TAG="${CN_TAG}"
SMF_REPO="${OAISA_REPO}/oai-smf"
SMF_TAG="${CN_TAG}"

# OAI5G RAN docker images
RAN_TAG="develop"

GNB_AW2S_REPO="docker.io/r2labuser/oai-gnb-aw2s"
#GNB_AW2S_TAG="new"
GNB_AW2S_TAG="rocky"
GNB_B210_REPO="${OAISA_REPO}/oai-gnb"
GNB_B210_TAG="${RAN_TAG}"
#GNB_B210_TAG="2023.w11b"
GNB_N3XX_REPO="${OAISA_REPO}/oai-gnb"
#GNB_N3XX_REPO="docker.io/r2labuser/oai-gnb"
GNB_N3XX_TAG="${RAN_TAG}"
#GNB_N3XX_TAG="bugfix-phy-mac-interface"
GNB_RFSIM_REPO="${OAISA_REPO}/oai-gnb"
GNB_RFSIM_TAG="${RAN_TAG}"
#GNB_RFSIM_TAG="2023.w12"
NRUE_REPO="${OAISA_REPO}/oai-nr-ue"
NRUE_TAG="${RAN_TAG}"
#NRUE_TAG="2023.w12"

####



function usage() {
    echo "USAGE:"
    echo "demo-oai.sh init [namespace] |"
    echo "            start [namespace node_amf_spgwu node_gnb rru gnb_only pcap] |"
    echo "            stop [namespace rru gnb_only pcap] |"
    echo "            configure-all [node_amf_spgwu node_gnb rru pcap] |"
    echo "            start-cn [namespace node_amf_spgwu] |"
    echo "            start-gnb [namespace node_gnb rru] |"
    echo "            start-nr-ue [namespace node_gnb] |"
    echo "            stop-cn [namespace] |"
    echo "            stop-gnb [namespace] |"
    echo "            stop-nr-ue [namespace] |"
    exit 1
}


function get-all-logs() {
    ns=$1; shift
    prefix=$1; shift
    rru=$1; shift

DATE=`date +"%Y-%m-%dT%H.%M.%S"`

AMF_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[0].metadata.name}")
AMF_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-amf $AMF_POD_NAME running with IP $AMF_eth0_IP"
kubectl --namespace $ns -c amf logs $AMF_POD_NAME > "$prefix"/amf-"$DATE".logs

AUSF_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-ausf" -o jsonpath="{.items[0].metadata.name}")
AUSF_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-ausf,app.kubernetes.io/instance=oai-ausf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-ausf $AUSF_POD_NAME running with IP $AUSF_eth0_IP"
kubectl --namespace $ns -c ausf logs $AUSF_POD_NAME > "$prefix"/ausf-"$DATE".logs

GNB_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
GNB_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-gnb $GNB_POD_NAME running with IP $GNB_eth0_IP"
kubectl --namespace $ns -c gnb logs $GNB_POD_NAME > "$prefix"/gnb-"$DATE".logs

NRF_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-nrf" -o jsonpath="{.items[0].metadata.name}")
NRF_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-nrf,app.kubernetes.io/instance=oai-nrf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-nrf $NRF_POD_NAME running with IP $NRF_eth0_IP"
kubectl --namespace $ns -c nrf logs $NRF_POD_NAME > "$prefix"/nrf-"$DATE".logs

SMF_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-smf" -o jsonpath="{.items[0].metadata.name}")
SMF_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-smf,app.kubernetes.io/instance=oai-smf" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-smf $SMF_POD_NAME running with IP $SMF_eth0_IP"
kubectl --namespace $ns -c smf logs $SMF_POD_NAME > "$prefix"/smf-"$DATE".logs

SPGWU_TINY_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-spgwu-tiny,app.kubernetes.io/instance=oai-spgwu-tiny" -o jsonpath="{.items[0].metadata.name}")
SPGWU_TINY_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-spgwu-tiny,app.kubernetes.io/instance=oai-spgwu-tiny" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-spgwu-tiny $SPGWU_TINY_POD_NAME running with IP $SPGWU_TINY_eth0_IP"
kubectl --namespace $ns -c spgwu logs $SPGWU_TINY_POD_NAME > "$prefix"/spgwu-tiny-"$DATE".logs

UDM_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-udm" -o jsonpath="{.items[0].metadata.name}")
UDM_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-udm,app.kubernetes.io/instance=oai-udm" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-udm $UDM_POD_NAME running with IP $UDM_eth0_IP"
kubectl --namespace $ns -c udm logs $UDM_POD_NAME > "$prefix"/udm-"$DATE".logs

UDR_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-udr" -o jsonpath="{.items[0].metadata.name}")
UDR_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-udr,app.kubernetes.io/instance=oai-udr" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-udr $UDR_POD_NAME running with IP $UDR_eth0_IP"
kubectl --namespace $ns -c udr logs $UDR_POD_NAME > "$prefix"/udr-"$DATE".logs

if [[ "$rru" == "rfsim" ]]; then
NRUE_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
NRUE_eth0_IP=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[*].status.podIP}")
echo -e "\t - Retrieving logs for oai-nr-ue $NRUE_POD_NAME running with IP $NRUE_eth0_IP"
kubectl --namespace $ns -c nr-ue logs $NRUE_POD_NAME > "$prefix"/nr-ue-"$DATE".logs
fi

echo "Retrieve gnb config from the pod"
if [[ "$rru" == "jaguar" || "$rru" == "panther" ]]; then
    kubectl -c gnb cp $ns/$GNB_POD_NAME:/opt/oai-gnb-aw2s/etc/gnb.conf $prefix/gnb.conf || true
else
    kubectl -c gnb cp $ns/$GNB_POD_NAME:/opt/oai-gnb/etc/gnb.conf $prefix/gnb.conf || true
fi

echo "Retrieve nrL1_stats.log, nrMAC_stats.log and nrRRC_stats.log from gnb pod"
kubectl -c gnb cp $ns/$GNB_POD_NAME:nrL1_stats.log $prefix/nrL1_stats.log"$DATE" || true
kubectl -c gnb cp $ns/$GNB_POD_NAME:nrMAC_stats.log $prefix/nrMAC_stats.log"$DATE" || true
kubectl -c gnb cp $ns/$GNB_POD_NAME:nrRRC_stats.log $prefix/nrRRC_stats.log"$DATE" || true
}


function get-cn-pcap(){
    ns=$1; shift
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    AMF_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G CN pcap files from the AMF pod on ns $ns"
    echo "kubectl -c tcpdump -n $ns exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz -C tmp pcap"
    kubectl -c tcpdump -n $ns exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz -C tmp pcap || true
    echo "kubectl -c tcpdump cp $ns/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap.tgz"
    kubectl -c tcpdump cp $ns/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap-"$DATE".tgz || true
}


function get-ran-pcap(){
    ns=$1; shift
    prefix=$1; shift
    rru=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    GNB_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G gnb pcap file from the oai-gnb pod on ns $ns"
    echo "kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz gnb-pcap.tgz pcap"
    kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz gnb-pcap.tgz pcap || true
    echo "kubectl -c tcpdump cp $ns/$GNB_POD_NAME:gnb-pcap.tgz $prefix/gnb-pcap-"$DATE".tgz"
    kubectl -c tcpdump cp $ns/$GNB_POD_NAME:gnb-pcap.tgz $prefix/gnb-pcap-"$DATE".tgz || true
    if [[ "$rru" == "rfsim" ]]; then
	NRUE_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
	echo "Retrieve OAI5G pcap file from the oai-nr-ue pod on ns $ns"
	echo "kubectl -c tcpdump -n $ns exec -i $NRUE_POD_NAME -- /bin/tar cfz nr-ue-pcap.tgz pcap"
	kubectl -c tcpdump -n $ns exec -i $NRUE_POD_NAME -- /bin/tar cfz nr-ue-pcap.tgz pcap || true
	echo "kubectl -c tcpdump cp $ns/$NRUE_POD_NAME:nr-ue-pcap.tgz $prefix/nr-ue-pcap-"$DATE".tgz"
	kubectl -c tcpdump cp $ns/$NRUE_POD_NAME:nr-ue-pcap.tgz $prefix/nr-ue-pcap-"$DATE".tgz || true
    fi
}


function get-all-pcap(){
    ns=$1; shift
    prefix=$1; shift
    rru=$1; shift

    get-cn-pcap $ns $prefix $rru
    get-ran-pcap $ns $prefix $rru
}



function configure-oai-5g-basic() {
    node_amf_spgwu=$1; shift
    pcap=$1; shift
    multus=$1; shift
    
    if [[ $pcap == "True" ]]; then
	echo "Modify CN charts to generate pcap files"
	PRIVILEGED="true"
	cat > /tmp/pcap.sed <<EOF
s|tcpdump: false.*|tcpdump: true|
s|sharedvolume:.*|sharedvolume: true|
EOF
	cp "$OAI5G_AMF"/values.yaml /tmp/amf_values.yaml-orig
	echo "(Over)writing $OAI5G_AMF/values.yaml"
	sed -f /tmp/pcap.sed < /tmp/amf_values.yaml-orig > "$OAI5G_AMF"/values.yaml
	diff /tmp/amf_values.yaml-orig "$OAI5G_AMF"/values.yaml
	cp "$OAI5G_AUSF"/values.yaml /tmp/ausf_values.yaml-orig
	echo "(Over)writing $OAI5G_AUSF/values.yaml"
	sed -f /tmp/pcap.sed < /tmp/ausf_values.yaml-orig > "$OAI5G_AUSF"/values.yaml
	diff /tmp/ausf_values.yaml-orig "$OAI5G_AUSF"/values.yaml
	cp "$OAI5G_SMF"/values.yaml /tmp/smf_values.yaml-orig
	echo "(Over)writing $OAI5G_SMF/values.yaml"
	sed -f /tmp/pcap.sed < /tmp/smf_values.yaml-orig > "$OAI5G_SMF"/values.yaml
	diff /tmp/smf_values.yaml-orig "$OAI5G_SMF"/values.yaml
	cp "$OAI5G_SPGWU"/values.yaml /tmp/spgwu-tiny_values.yaml-orig
	echo "(Over)writing $OAI5G_SPGWU/values.yaml"
	sed -f /tmp/pcap.sed < /tmp/spgwu-tiny_values.yaml-orig > "$OAI5G_SPGWU"/values.yaml
	diff /tmp/spgwu-tiny_values.yaml-orig "$OAI5G_SPGWU"/values.yaml
    else
	PRIVILEGED="false"
    fi

    if [[ $multus == "true" ]]; then
	NET_IF="net1"
    else
	NET_IF="eth0"
    fi
    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    if [[ $pcap == "True" ]]; then
	tcpdump="true"
    else
	tcpdump="false"
    fi
    cat > /tmp/basic-r2lab.sed <<EOF
s|privileged:.*|privileged: $PRIVILEGED|
s|create: false|create: $multus|
s|includeTcpDumpContainer:.*|includeTcpDumpContainer: $tcpdump|
s|n2IPadd:.*|n2IPadd: "$IP_AMF_N2"|
s|n2Netmask:.*|n2Netmask: "24"|
s|defaultGateway:.*|defaultGateway: |
s|hostInterface:.*|hostInterface: "$IF_NAME_AMF_N2_SPGWU_N3" # interface of the nodes for amf/N2 and spgwu/N3|
s|amfInterfaceNameForNGAP:.*|amfInterfaceNameForNGAP: "$NET_IF" # If multus creation is true then net1 else eth0|
s|mcc:.*|mcc: "$MCC"|
s|mnc:.*|mnc: "$MNC"|
s|nssaiSd0:.*|nssaiSd0: "0xFFFFFF" # empty so will be set by configmap chart|
s|n3Ip:.*|n3Ip: "$IP_UPF_N3"|
s|n3Netmask:.*|n3Netmask: "24"|
s|n3If:.*|n3If: "$NET_IF"  # net1 if gNB is outside the cluster network and multus creation is true else eth0|
s|n6If:.*|n6If: "$NET_IF"  # net1 if gNB is outside the cluster network and multus creation is true else eth0  (important because it sends the traffic towards internet)|
s|dnsIpv4Address:.*|dnsIpv4Address: "138.96.0.210" # configure the dns for UE don't use Kubernetes DNS|
s|dnsSecIpv4Address:.*|dnsSecIpv4Address: "193.51.196.138" # configure the dns for UE don't use Kubernetes DNS|
s|dnn0:.*|dnn0: "$DNN"|
s|dnnNi0:.*|dnnNi0: "$DNN"|
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
s|@SPGWU_REPO@|${SPGWU_REPO}|
s|@SPGWU_TAG@|${SPGWU_TAG}|
s|@SMF_REPO@|${SMF_REPO}|
s|@SMF_TAG@|${SMF_TAG}|
EOF

    cp "$OAI5G_BASIC"/values.yaml /tmp/basic_values.yaml-orig
    echo "(Over)writing $OAI5G_BASIC/values.yaml"
    sed -f /tmp/basic-r2lab.sed < /tmp/basic_values.yaml-orig > "$OAI5G_BASIC"/values.yaml
    perl -i -p0e "s/nodeSelector: \{\}\noai-smf:/nodeName: \"$node_amf_spgwu\"\n  nodeSelector: \{\}\noai-smf:/s" "$OAI5G_BASIC"/values.yaml
    perl -i -p0e "s/nodeSelector: \{\}\noai-spgwu-tiny:/nodeName: \"$node_amf_spgwu\"\n  nodeSelector: \{\}\noai-spgwu-tiny:/s" "$OAI5G_BASIC"/values.yaml

    diff /tmp/basic_values.yaml-orig "$OAI5G_BASIC"/values.yaml
        
    cd "$OAI5G_BASIC"
    echo "helm dependency update"
    helm dependency update
}


function configure-mysql() {

    FUNCTION="mysql"
    DIR="$OAI5G_CORE/$FUNCTION/initialization"
    ORIG_CHART="$OAI5G_CORE/$FUNCTION"/initialization/oai_db-basic.sql
    SED_FILE="/tmp/$FUNCTION-r2lab.sed"

    echo "Configuring chart $ORIG_CHART for R2lab"
    echo "Applying patch to add R2lab SIM info in AuthenticationSubscription table"
    rm -f /tmp/oai_db-basic-patch
    cat << \EOF >> /tmp/oai_db-basic-patch
--- oai_db-basic-orig.sql	2023-05-04 23:18:49.000000000 +0200
+++ oai_db-basic-new.sql	2023-05-05 17:16:12.000000000 +0200
@@ -150,31 +150,21 @@
 -- Dumping data for table `AuthenticationSubscription`
 --
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000100', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000100');
+('@DEF_MCC@@DEF_MNC@0000000002', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000002');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000101', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000101');
+('@DEF_MCC@@DEF_MNC@0000000010', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000010');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000102', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000102');
+('@DEF_MCC@@DEF_MNC@0000000011', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000011');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000103', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000103');
+('@DEF_MCC@@DEF_MNC@0000000012', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000012');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000104', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000104');
+('@DEF_MCC@@DEF_MNC@0000000013', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000013');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000105', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000105');
+('@DEF_MCC@@DEF_MNC@0000000014', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000014');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000106', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000106');
+('@DEF_MCC@@DEF_MNC@0000000015', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_MCC@@DEF_MNC@0000000015');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000107', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000107');
-INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000108', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000108');
-INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000109', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000109');
-INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000110', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000110');
-INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000111', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000111');
-INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000112', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000112');
+('@DEF_RFSIM_IMSI@', '5G_AKA', '@DEF_FULL_KEY@', '@DEF_FULL_KEY@', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '@DEF_OPC@', NULL, NULL, NULL, NULL, '@DEF_RFSIM_IMSI@');
 
 
 -- --------------------------------------------------------
@@ -319,36 +309,23 @@
 --
 -- AUTO_INCREMENT for dumped tables
 --
+-- Dynamic IPADDRESS Allocation
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000100', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.100\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('@DEF_MCC@@DEF_MNC@0000000002', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000101', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.101\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('@DEF_MCC@@DEF_MNC@0000000010', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000102', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.102\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('@DEF_MCC@@DEF_MNC@0000000011', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000103', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.103\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('@DEF_MCC@@DEF_MNC@0000000012', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000104', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.104\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('@DEF_MCC@@DEF_MNC@0000000013', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000105', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.105\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-
--- Dynamic IPADDRESS Allocation
-
+('@DEF_MCC@@DEF_MNC@0000000014', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('208950000000013', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
-('001010000000106', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
-('001010000000107', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
-('001010000000109', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
-('001010000000110', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
-('001010000000111', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
-('001010000000112', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
-
+('@DEF_MCC@@DEF_MNC@0000000015', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
+('@DEF_RFSIM_IMSI@', '@DEF_MCC@@DEF_MNC@', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"@DEF_DNN@\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 
 
 --
EOF
    patch "$ORIG_CHART" < /tmp/oai_db-basic-patch
}


function configure-amf() {

    FUNCTION="oai-amf"
    DIR="$OAI5G_CORE/$FUNCTION"
    ORIG_CHART="$OAI5G_CORE/$FUNCTION"/templates/deployment.yaml
    echo "Configuring chart $ORIG_CHART for R2lab"

    cp "$ORIG_CHART" /tmp/"$FUNCTION"_deployment.yaml-orig
    perl -i -p0e 's/-n2-net1"/-n2-net1",\n                "mac": "12:34:56:78:90:00"/s' "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_deployment.yaml-orig "$ORIG_CHART"
}


function configure-spgwu-tiny() {

    FUNCTION="oai-spgwu-tiny"
    DIR="$OAI5G_CORE/$FUNCTION"
    ORIG_CHART="$OAI5G_CORE/$FUNCTION"/templates/deployment.yaml
    echo "Configuring chart $ORIG_CHART for R2lab"

    cp "$ORIG_CHART" /tmp/"$FUNCTION"_deployment.yaml-orig
    perl -i -p0e 's/-n3-net1"/-n3-net1",\n                "mac": "12:34:56:78:90:01"/s' "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_deployment.yaml-orig "$ORIG_CHART"
}


function configure-gnb() {
    node_gnb=$1; shift
    rru=$1; shift
    pcap=$1; shift
    

    # Prepare mounted.conf and gnb chart files
    echo "configure-gnb: gNB on node $node_gnb with RRU $rru and pcap is $pcap"
    echo "First prepare gNB mounted.conf and values/multus/configmap/deployment charts for $rru"

    FUNCTION="oai-gnb"
    DIR_RAN="/root/oai5g-rru/ran-config"
    DIR_CONF="$DIR_RAN/conf"
    DIR_CHARTS="$DIR_RAN/charts"
    DIR_GNB_DEST="/root/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb"
    DIR_TEMPLATES="$DIR_GNB_DEST/templates"

    SED_CONF_FILE="/tmp/gnb_conf.sed"
    SED_VALUES_FILE="/tmp/$FUNCTION-values.sed"
    SED_DEPLOYMENT_FILE="/tmp/$FUNCTION-deployment.sed"

    if [[ $pcap == "True" ]]; then
	TCPDUMP_CONTAINER_GNB_CREATE="true"
	TCPDUMP_GNB_START="true"
	GNB_SHARED_VOL="true"
    else
	TCPDUMP_CONTAINER_GNB_CREATE="false"
	TCPDUMP_GNB_START="false"
	GNB_SHARED_VOL="false"
    fi

    GNB_NAME="gNB_R2lab"
    # Configure parameters for values.yaml chart according to RRU type
    if [[  "$rru" == "b210" ]]; then
	# no multus;  @var@ will be used to set AMF/NGA/NGU IP addresses just before the gnb starts
	CONF_ORIG="$DIR_CONF/$CONF_B210"
	GNB_REPO="$GNB_B210_REPO"
	GNB_TAG="$GNB_B210_TAG"
	GNB_NAME="$GNB_NAME-b210"
	if [[ $DEF_GNB_ONLY == "True" ]]; then
	    MULTUS_GNB_N2N3="true"
	    GNB_NGA_IF_NAME="$IF_NAME_GNB_N2N3"
	    GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3"
	    GNB_NGU_IF_NAME="$IF_NAME_GNB_N2N3"
	    GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3"
	else
	    MULTUS_GNB_N2N3="false"
	    GNB_NGA_IF_NAME="eth0"
	    GNB_NGA_IP_ADDRESS="@GNB_NGA_IP_ADDRESS@"
	    GNB_NGU_IF_NAME="eth0"
	    GNB_NGU_IP_ADDRESS="@GNB_NGU_IP_ADDRESS@"
	fi
	MULTUS_GNB_RU1="false"
	IP_GNB_RU1=""
	MTU_GNB_RU1=""
	IF_NAME_GNB_RU1=""
	MULTUS_GNB_RU2="false"
	IP_GNB_RU2=""
	MTU_GNB_RU2=""
	IF_NAME_GNB_RU2=""
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="b210"
	ADD_OPTIONS_GNB="--sa -E --tune-offset 30000000 --log_config.global_log_options level,nocolor,time"
	QOS_GNB_DEF="false"

    elif [[ "$rru" == "n300" || "$rru" == "n320" ]]; then
	if [[ "$rru" == "n300" ]]; then
	    GNB_NAME="$GNB_NAME-n300"
	    SDR_ADDRS="$ADDRS_N300"
	elif [[ "$rru" == "n320" ]]; then
	    GNB_NAME="$GNB_NAME-n320"
	    SDR_ADDRS="$ADDRS_N320"
	fi
	CONF_ORIG="$DIR_CONF/$CONF_N3XX"
	GNB_REPO="$GNB_N3XX_REPO"
	GNB_TAG="$GNB_N3XX_TAG"
	GNB_NGA_IF_NAME="net1"
	GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_NGU_IF_NAME="net1"
	GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3/24"
	MULTUS_GNB_N2N3="true"
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
	ADD_OPTIONS_GNB="--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"
	QOS_GNB_DEF="true"
    elif [[ "$rru" == "jaguar" || "$rru" == "panther" ]]; then
	if [[  "$rru" == "jaguar" ]]; then
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
	GNB_NGA_IF_NAME="net1"
	GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_NGU_IF_NAME="net1"
	GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_AW2S_IF_NAME="net1"
	MULTUS_GNB_N2N3="true"
	MULTUS_GNB_RU1="false"
	IP_GNB_RU1=""
	MTU_GNB_RU1=""
	IF_NAME_GNB_RU1=""
	MULTUS_GNB_RU2="false"
	IP_GNB_RU2=""
	MTU_GNB_RU2=""
	IF_NAME_GNB_RU2=""
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="aw2s"
	ADD_OPTIONS_GNB="--sa --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"
	QOS_GNB_DEF="true"
	
    elif [[ "$rru" == "rfsim" ]]; then
        GNB_NAME="$GNB_NAME-rfsim"
	CONF_ORIG="$DIR_CONF/$CONF_RFSIM"
	GNB_REPO="$GNB_RFSIM_REPO"
	GNB_TAG="$GNB_RFSIM_TAG"
	GNB_NGA_IF_NAME="net1"
	GNB_NGA_IP_ADDRESS="$IP_GNB_N2N3/24"
	GNB_NGU_IF_NAME="net1"
	GNB_NGU_IP_ADDRESS="$IP_GNB_N2N3/24"
	MULTUS_GNB_N2N3="true"
	MULTUS_GNB_RU1="false"
	IP_GNB_RU1=""
	MTU_GNB_RU1=""
	IF_NAME_GNB_RU1=""
	MULTUS_GNB_RU2="false"
	IP_GNB_RU2=""
	MTU_GNB_RU2=""
	IF_NAME_GNB_RU2=""
	MOUNTCONFIG_GNB="true"
	RRU_TYPE="rfsim"
	ADD_OPTIONS_GNB="--sa -E --rfsim --log_config.global_log_options level,nocolor,time"
	QOS_GNB_DEF="false"

    else
	echo "Unknown rru selected: $rru"
	usage
    fi
    
    echo "Copy the modified chart files in the right place"
    echo cp "$DIR_CHARTS"/values.yaml "$DIR_GNB_DEST"/values.yaml
    cp "$DIR_CHARTS"/values.yaml "$DIR_GNB_DEST"/values.yaml
    echo cp "$DIR_CHARTS"/deployment.yaml "$DIR_TEMPLATES"/deployment.yaml
    cp "$DIR_CHARTS"/deployment.yaml "$DIR_TEMPLATES"/deployment.yaml
    if [[ $DEF_GNB_ONLY == "True" ]]; then
	GW_N2N3="true"
	SED_MULTUS_FILE="/tmp/gnb_multus.sed"
	cat > "$SED_MULTUS_FILE" <<EOF
s|@ROUTE_GNB_TO_EXTCN@|$ROUTE_GNB_TO_EXTCN|
s|@GW_GNB_TO_EXTCN|$GW_GNB_TO_EXTCN|
EOF
	sed -f "$SED_MULTUS_FILE" < "$DIR_CHARTS"/multus.yaml > "$DIR_TEMPLATES"/multus.yaml
	echo "configure chart multus for gnb"
	cat "$DIR_TEMPLATES"/multus.yaml
    else
	GW_N2N3="false"
	echo cp "$DIR_CHARTS"/multus.yaml "$DIR_TEMPLATES"/multus.yaml
	cp "$DIR_CHARTS"/multus.yaml "$DIR_TEMPLATES"/multus.yaml
    fi
    
    echo "Set up configmap.yaml chart with the right gNB configuration from $CONF_ORIG"
    # Keep the 17 first lines of configmap.yaml
    head -17  "$DIR_CHARTS"/configmap.yaml > /tmp/configmap.yaml
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
s|@SST@|$SST|
s|@AMF_IP_ADDRESS@|$IP_AMF_N2|
s|@GNB_NGA_IF_NAME@|$GNB_NGA_IF_NAME|
s|@GNB_NGA_IP_ADDRESS@|$GNB_NGA_IP_ADDRESS|
s|@GNB_NGU_IF_NAME@|$GNB_NGU_IF_NAME|
s|@GNB_NGU_IP_ADDRESS@|$GNB_NGU_IP_ADDRESS|
s|@AW2S_IP_ADDRESS@|$ADDR_AW2S|
s|@GNB_AW2S_IP_ADDRESS@|$IP_AW2S|
s|@GNB_AW2S_IF_NAME@|$GNB_AW2S_IF_NAME|
s|@SDR_ADDRS@|$SDR_ADDRS,clock_source=internal,time_source=internal|
EOF
    cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
    sed -f "$SED_CONF_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
    echo "Display new $DIR_TEMPLATES/configmap.yaml"
    cat "$DIR_TEMPLATES"/configmap.yaml

    # Configure gnb values.yaml chart
    DIR="$OAI5G_RAN/$FUNCTION"

    echo "Then configure charts of oai-gnb"
    cat > "$SED_VALUES_FILE" <<EOF
s|@GNB_REPO@|$GNB_REPO|
s|@GNB_TAG@|$GNB_TAG|
s|@MULTUS_GNB_N2N3@|$MULTUS_GNB_N2N3|
s|@IP_GNB_N2N3@|$IP_GNB_N2N3|
s|@NETMASK_GNB_N2N3@|$NETMASK_GNB_N2N3|
s|@IF_NAME_GNB_N2N3@|$IF_NAME_GNB_N2N3|
s|@GW_N2N3@|$GW_N2N3|
s|@MULTUS_GNB_RU1@|$MULTUS_GNB_RU1|
s|@IP_GNB_RU1@|$IP_GNB_RU1|
s|@NETMASK_GNB_RU1@|$NETMASK_GNB_RU1|
s|@MTU_GNB_RU1@|$MTU_GNB_RU1|
s|@IF_NAME_GNB_RU1@|$IF_NAME_GNB_RU1|
s|@MULTUS_GNB_RU2@|$MULTUS_GNB_RU2|
s|@IP_GNB_RU2@|$IP_GNB_RU2|
s|@NETMASK_GNB_RU2@|$NETMASK_GNB_RU2|
s|@MTU_GNB_RU2@|$MTU_GNB_RU2|
s|@IF_NAME_GNB_RU2@|$IF_NAME_GNB_RU2|
s|@MOUNTCONFIG_GNB@|$MOUNTCONFIG_GNB|
s|@RRU_TYPE@|$RRU_TYPE|
s|@ADD_OPTIONS_GNB@|$ADD_OPTIONS_GNB|
s|@TCPDUMP_GNB_START@|$TCPDUMP_GNB_START|
s|@TCPDUMP_CONTAINER_GNB_CREATE@|$TCPDUMP_CONTAINER_GNB_CREATE|
s|@GNB_SHARED_VOL@|$GNB_SHARED_VOL|
s|@QOS_GNB_DEF@|$QOS_GNB_DEF|
s|@NB_CPU_GNB@|$NB_CPU_GNB|
s|@MEMORY_GNB@|$MEMORY_GNB|
s|nodeName:.*|nodeName: $node_gnb|
EOF
    ORIG_CHART="$DIR"/values.yaml
    cp "$ORIG_CHART" /tmp/"$FUNCTION"_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_VALUES_FILE" < /tmp/"$FUNCTION"_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_values.yaml-orig "$ORIG_CHART" 
}


function configure-nr-ue() {
    pcap=$1; shift
    
    FUNCTION="oai-nr-ue"
    DIR="$OAI5G_RAN/$FUNCTION"
    DIR_TEMPLATES="$DIR"/templates

    DIR_RAN="/root/oai5g-rru/ran-config"
    DIR_CHARTS="$DIR_RAN/charts"

    echo "Copy the nr-ue chart files"
    echo cp "$DIR_CHARTS"/nr-ue-values-rfsim.yaml "$DIR"/values.yaml
    cp "$DIR_CHARTS"/nr-ue-values-rfsim.yaml "$DIR"/values.yaml
    echo cp "$DIR_CHARTS"/nr-ue-deployment-rfsim.yaml "$DIR_TEMPLATES"/deployment.yaml
    cp "$DIR_CHARTS"/nr-ue-deployment-rfsim.yaml "$DIR_TEMPLATES"/deployment.yaml
    echo cp "$DIR_CHARTS"/nr-ue-multus-rfsim.yaml "$DIR_TEMPLATES"/multus.yaml
    cp "$DIR_CHARTS"/nr-ue-multus-rfsim.yaml "$DIR_TEMPLATES"/multus.yaml
    
    if [[ $pcap == "True" ]]; then
	TCPDUMP_CONTAINER_NRUE_CREATE="true"
	echo "nr-ue: will NOT generate PCAP file to avoid wasting all memory resources!"
	echo "However, a tcpdump container will be created for testing purpose"
    else
	TCPDUMP_CONTAINER_NRUE_CREATE="false"
    fi

    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="/tmp/$FUNCTION-values.sed"
    echo "Configuring chart $ORIG_CHART"
    ADD_OPTIONS_NRUE="--sa --rfsim -r 106 --numerology 1 -C 3619200000 --nokrnmod"
    SSD="16777215"
    cat > "$SED_FILE" <<EOF
s|@NRUE_REPO@|$NRUE_REPO|
s|@NRUE_TAG@|$NRUE_TAG|
s|@MULTUS_NRUE@|true|
s|@IP_NRUE@|$IP_NRUE|
s|@NETMASK_NRUE@|$NETMASK_NRUE|
s|@IF_NAME_NRUE@|$IF_NAME_NRUE|
s|@IP_GNB@|$IP_GNB_N2N3|
s|@RFSIM_IMSI@|$RFSIM_IMSI|
s|@FULL_KEY@|$FULL_KEY|
s|@OPC@|$OPC|
s|@DNN@|$DNN|
s|@SST@|$SST|
s|@SSD@|$SSD|
s|@ADD_OPTIONS_NRUE@|$ADD_OPTIONS_NRUE|
s|@TCPDUMP_NRUE_START@|false|
s|@TCPDUMP_CONTAINER_NRUE_CREATE@|$TCPDUMP_CONTAINER_NRUE_CREATE|
s|@SHARED_VOL_NRUE@|false|
s|@QOS_NRUE_DEF@|false|
s|nodeName:.*|nodeName:|
EOF
    cp "$ORIG_CHART" /tmp/"$FUNCTION"_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < /tmp/"$FUNCTION"_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_values.yaml-orig "$ORIG_CHART"
}


function configure-all() {
    node_amf_spgwu=$1; shift
    node_gnb=$1; shift
    rru=$1; shift
    pcap=$1; shift

    echo "configure-all: Applying SophiaNode patches to OAI5G charts located on "$HOME"/oai-cn5g-fed"
    echo -e "\t with oai-spgwu-tiny running on $node_amf_spgwu"
    echo -e "\t with oai-gnb running on $node_gnb"
    echo -e "\t with generate-pcap: $pcap"

    if [[ "$rru" == "b210" ]]; then
	configure-oai-5g-basic $node_amf_spgwu $pcap false
    else
	configure-oai-5g-basic $node_amf_spgwu $pcap true
    fi	
    configure-mysql
    configure-amf
    configure-spgwu-tiny
    configure-gnb $node_gnb $rru $pcap
    if [[ "$rru" == "rfsim" ]]; then
	configure-nr-ue $pcap
    fi
}



function init() {
    ns=$1; shift

    # init function should be run once per demo.

    # Remove pulling limitations from docker-hub with anonymous account
    echo "init: create regcred secret"	     
    kubectl create namespace $ns || true
    kubectl -n$ns delete secret regcred || true
    kubectl -n$ns create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=r2labuser --docker-password=r2labuser-pwd --docker-email=r2labuser@turletti.com || true

    # Ensure that helm spray plugin is installed
    echo "init: ensure spray is installed and possibly create secret docker-registry"
    helm plugin uninstall helm-spray || true
    helm plugin install https://github.com/ThalesGroup/helm-spray || true

    # Just in case the k8s cluster has been restarted without multus enabled..
    echo "kube-install.sh enable-multus"
    kube-install.sh enable-multus || true

    # Install patch command...
    if [ ! -x "$(command -v patch)" ]; then
        [[ -f /etc/fedora-release ]] && dnf install -y patch
        [[ -f /etc/lsb-release ]] && apt-get install -y patch
    fi  
}


function start-cn() {
    ns=$1
    shift
    node_amf_spgwu=$1
    shift

    echo "Running start-cn() with namespace: $ns, node_amf_spgwu:$node_amf_spgwu"

    echo "cd $OAI5G_BASIC"
    cd "$OAI5G_BASIC"

    echo "helm dependency update"
    helm dependency update

    echo "helm --namespace=$ns spray ."
    helm --create-namespace --namespace=$ns spray .

    echo "Wait until all 5G Core pods are READY"
    kubectl wait pod -n$ns --for=condition=Ready --all
}


function start-gnb() {
    ns=$1
    shift
    node_gnb=$1
    shift
    rru=$1
    shift

    echo "Running start-gnb() with namespace: $ns, node_gnb:$node_gnb with rru $rru"

    DIR="$OAI5G_RAN/oai-gnb"
    DIR_TEMPLATES="$DIR/templates"
    if [[ "$rru" == "b210" ]]; then
	echo "Set AMF IP address in gnb conf"
	if [[ $DEF_GNB_ONLY == "True" ]]; then
	    AMF_IP="$AMF_IP_ADDR" # external CN including AMF
	else
	    AMF_POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-amf -o jsonpath="{.items[0].metadata.name}")
	    AMF_IP=$(kubectl -n$ns get pod $AMF_POD_NAME --template '{{.status.podIP}}')
	fi
	SED_FILE="/tmp/gnb-configmap.sed"
	cat > "$SED_FILE" <<EOF
s|ipv4       =.*|ipv4       = "$AMF_IP";|
EOF
	cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
	sed -f "$SED_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
	diff  /tmp/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml
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

    echo "helm -n$ns install oai-gnb oai-gnb/"
    helm -n$ns install oai-gnb oai-gnb/

    echo "Wait until the gNB pod is READY"
    echo "kubectl -n$ns wait pod --for=condition=Ready --all"
    kubectl -n$ns wait pod --for=condition=Ready --all
}


function start-nr-ue() {
    ns=$1
    shift
    node_gnb=$1
    shift

    echo "Running start-nr-ue() on namespace: $ns, node_gnb:$node_gnb"

    echo "helm -n$ns install oai-nr-ue oai-nr-ue/"
    helm -n$ns install oai-nr-ue oai-nr-ue/

    echo "Wait until oai-nr-ue pod is READY"
    kubectl wait pod -n$ns --for=condition=Ready --all
}



function start() {
    ns=$1; shift
    node_amf_spgwu=$1; shift
    node_gnb=$1; shift
    rru=$1; shift
    gnb_only=$1; shift
    pcap=$1; shift

    echo "start: run all oai5g pods on namespace: $ns"

    if [[ $pcap == "True" ]]; then
	echo "start: Create a k8s persistence volume for generation of RAN pcap files"
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

	echo "start: Create a k8s persistence volume for generation of CN pcap files"
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

	
	echo "start: Create a k8s persistent volume claim for RAN pcap files"
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
    echo "kubectl -n $ns apply -f /tmp/oai5g-pvc.yaml"
    kubectl -n $ns apply -f /tmp/oai5g-pvc.yaml

	echo "start: Create a k8s persistent volume claim for CN pcap files"
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
    echo "kubectl -n $ns apply -f /tmp/cn5g-pvc.yaml"
    kubectl -n $ns apply -f /tmp/cn5g-pvc.yaml
    fi

    if [[ $gnb_only == "False" ]]; then
	start-cn $ns $node_amf_spgwu
    fi
    start-gnb $ns $node_gnb $rru

    if [[ "$rru" == "rfsim" ]]; then
	start-nr-ue $ns $node_gnb
    fi

    echo "****************************************************************************"
    echo "When you finish, to clean-up the k8s cluster, please run demo-oai.py --clean"
}


function run-ping() {
    ns=$1
    shift

    UE_POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-nr-ue -o jsonpath="{.items[0].metadata.name}")
    echo "kubectl -n$ns exec -it $UE_POD_NAME -c nr-ue -- /bin/ping --I oaitun_ue1 c4 google.fr"
    kubectl -n$ns exec -it $UE_POD_NAME -c nr-ue -- /bin/ping -I oaitun_ue1 -c4 google.fr
}


function stop-cn(){
    ns=$1
    shift

    echo "helm -n$ns uninstall oai-spgwu-tiny oai-nrf oai-udr oai-udm oai-ausf oai-smf oai-amf mysql"
    helm -n$ns uninstall oai-smf
    helm -n$ns uninstall oai-spgwu-tiny
    helm -n$ns uninstall oai-amf
    helm -n$ns uninstall oai-ausf
    helm -n$ns uninstall oai-udm
    helm -n$ns uninstall oai-udr
    helm -n$ns uninstall oai-nrf
    helm -n$ns uninstall mysql
}


function stop-gnb(){
    ns=$1
    shift

    echo "helm -n$ns uninstall oai-gnb"
    helm -n$ns uninstall oai-gnb
}


function stop-nr-ue(){
    ns=$1
    shift

    echo "helm -n$ns uninstall oai-nr-ue"
    helm -n$ns uninstall oai-nr-ue
}


function stop() {
    ns=$1; shift
    rru=$1; shift
    gnb_only=$1; shift
    pcap=$1; shift

    echo "Running stop() on namespace:$ns; pcap is $pcap"

    if [[ $pcap == "True" ]]; then
	dir_stats=${PREFIX_STATS-"/tmp/oai5g-stats"}
	echo "First retrieve all pcap and log files in $dir_stats and compressed it"
	mkdir -p $dir_stats
	echo "cleanup $dir_stats before including new logs/pcap files"
	cd $dir_stats; rm -f *.pcap *.tgz *.logs *stats* *.conf
	get-all-pcap $ns $dir_stats $rru
	get-all-logs $ns $dir_stats $rru
	cd /tmp; dirname=$(basename $dir_stats)
	echo tar cfz "$dirname".tgz $dirname
	tar cfz "$dirname".tgz $dirname
    fi

    res=$(helm -n $ns ls | wc -l)
    if test $res -gt 1; then
        echo "Remove all 5G OAI pods"
	if [[ $gnb_only == "False" ]]; then
	    stop-cn $ns
	fi
	stop-gnb $ns
	if [[ "$rru" == "rfsim" ]]; then
	    stop-nr-ue $ns
	fi
    else
        echo "OAI5G demo is not running, there is no pod on namespace $ns !"
    fi

    echo "Wait until all $ns pods disppear"
    kubectl delete pods -n $ns --all --wait --cascade=foreground

    if [[ $pcap == "True" ]]; then
	echo "Delete k8s persistence volume / claim for pcap files"
	kubectl -n $ns delete pvc oai5g-pvc || true
	kubectl -n $ns delete pvc cn5g-pvc || true
	kubectl delete pv oai5g-pv || true
	kubectl delete pv cn5g-pv || true
    fi
}


# ****************************************************************************** #
#Handle the different function calls with or without input parameters

if test $# -lt 1; then
    usage
else
    if [ "$1" == "init" ]; then
        if test $# -eq 2; then
            init $2
        elif test $# -eq 1; then
	    init $DEF_NS
        else
            usage
        fi
    elif [ "$1" == "start" ]; then
        if test $# -eq 7; then
            start $2 $3 $4 $5 $6 $7
        elif test $# -eq 1; then
	    start $DEF_NS $DEF_NODE_AMF_SPGWU $DEF_NODE_GNB $DEF_RRU $DEF_GNB_ONLY $DEF_PCAP
	else
            usage
        fi
    elif [ "$1" == "stop" ]; then
        if test $# -eq 5; then
            stop $2 $3 $4 $5
        elif test $# -eq 1; then
	    stop $DEF_NS $DEF_RRU $DEF_GNB_ONLY $DEF_PCAP
	else
            usage
        fi
    elif [ "$1" == "configure-all" ]; then
        if test $# -eq 5; then
            configure-all $2 $3 $4 $5
	    exit 0
        elif test $# -eq 1; then
	    configure-all $DEF_NODE_AMF_SPGWU $DEF_NODE_GNB $DEF_RRU $DEF_PCAP
	else
            usage
        fi
    elif [ "$1" == "start-cn" ]; then
        if test $# -eq 3; then
            start-cn $2 $3
        elif test $# -eq 1; then
	    start-cn $DEF_NS $DEF_NODE_AMF_SPGWU
	else
            usage
        fi
    elif [ "$1" == "start-gnb" ]; then
        if test $# -eq 4; then
            start-gnb $2 $3 $4
        elif test $# -eq 1; then
	    start-gnb $DEF_NS $DEF_NODE_GNB $DEF_RRU
	else
            usage
        fi
    elif [ "$1" == "start-nr-ue" ]; then
        if test $# -eq 3; then
            start-nr-ue $2 $3
        elif test $# -eq 1; then
	    start-nr-ue $DEF_NS $DEF_NODE_GNB
	else
            usage
        fi
    elif [ "$1" == "stop-cn" ]; then
        if test $# -eq 2; then
            stop-cn $2
        elif test $# -eq 1; then
	    stop-cn $DEF_NS
	else
            usage
        fi
    elif [ "$1" == "stop-gnb" ]; then
        if test $# -eq 2; then
            stop-gnb $2
        elif test $# -eq 1; then
	    stop-gnb $DEF_NS
	else
            usage
        fi
    elif [ "$1" == "stop-nr-ue" ]; then
        if test $# -eq 2; then
            stop-nr-ue $2
        elif test $# -eq 1; then
	    stop-nr-ue $DEF_NS
	else
            usage
        fi
    else
        usage
    fi
fi
