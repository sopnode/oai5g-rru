#!/bin/bash


##########################################################################
# Following parameters automatically set by configure-demo-oai.sh script
# do not change them here !
DEF_NS= # k8s namespace
DEF_NODE_AMF_SPGWU= # node in wich run amf and spgwu pods
DEF_NODE_GNB= # node in which gnb pod runs
DEF_RRU= # in ['b210', 'n300', 'n320', 'jaguar', 'panther', 'rfsim']
DEF_PCAP= # boolean if pcap are generated on pods
##########################################################################

PREFIX_STATS="/tmp/oai5g-stats"

# IP Pod addresses
P100="192.168.100"
IP_AMF_N2="$P100.241"
IP_UPF_N3="$P100.242"
IP_GNB_N2="$P100.243"
IP_GNB_N3="$P100.244"
IP_GNB_N2N3="$P100.243"
IP_GNB_AW2S="$P100.245" 
IP_NRUE="$P100.246" 

# Interfaces names of VLANs in sopnode servers
IF_NAME_VLAN100="p4-net"
IF_NAME_VLAN10="p4-net-10"
IF_NAME_VLAN20="p4-net-20"

# IP addresses of RRU devices
## USRP N3XX devices
ADDRS_N300="addr=192.168.10.129,second_addr=192.168.20.129,mgmt_addr=192.168.3.151"
ADDRS_N320="addr=192.168.10.130,second_addr=192.168.20.130,mgmt_addr=192.168.3.152"
## AW2S devices
ADDR_JAGUAR="$P100.48" # for eth1
ADDR_PANTHER="$P100.51" # .51 for eth2

# N2/N3 Interfaces definition
IF_NAME_AMF_N2_SPGWU_N3="$IF_NAME_VLAN100"
IF_NAME_GNB_N2="$IF_NAME_VLAN100"
IF_NAME_GNB_N3="$IF_NAME_VLAN100"
IF_NAME_LOCAL_AW2S="$IF_NAME_VLAN100"
IF_NAME_LOCAL_N3XX_1="$IF_NAME_VLAN10"
IF_NAME_LOCAL_N3XX_2="$IF_NAME_VLAN20"
IF_NAME_NRUE="$IF_NAME_VLAN100"

# gNB conf file for RRU devices
CONF_JAGUAR="jaguar_panther2x2_50MHz.conf"
CONF_PANTHER="panther4x4_20MHz.conf"
CONF_B210="gnb.sa.band78.fr1.24PRB.usrpb210.conf"
CONF_N3XX="gnb.band78.sa.fr1.106PRB.2x2.usrpn310.conf"
CONF_RFSIM="gnb.sa.band78.106prb.rfsim.2x2.conf"

OAI5G_CHARTS="$HOME"/oai-cn5g-fed/charts
OAI5G_CORE="$OAI5G_CHARTS"/oai-5g-core
OAI5G_BASIC="$OAI5G_CORE"/oai-5g-basic
OAI5G_RAN="$OAI5G_CHARTS"/oai-5g-ran
OAI5G_AMF="$OAI5G_CORE"/oai-amf
OAI5G_AUSF="$OAI5G_CORE"/oai-ausf
OAI5G_SMF="$OAI5G_CORE"/oai-smf
OAI5G_SPGWU="$OAI5G_CORE"/oai-spgwu-tiny
OAI5G_NRUE="$OAI5G_CORE"/oai-nr-ue

# Other configurable CN parameters 
MCC="208"
MNC="95"
DNN="oai.ipv4"
FULL_KEY="8baf473f2f8fd09487cccbd7097c6862"
OPC="8E27B6AF0E692E750F32667A3B14605D"
RFSIM_IMSI="208950000001121"

function usage() {
    echo "USAGE:"
    echo "demo-oai.sh init [namespace] |"
    echo "            start [namespace node_amf_spgwu node_gnb rru pcap] |"
    echo "            stop [namespace rru pcap] |"
    echo "            configure-all [node_amf_spgwu node_gnb rru pcap] |"
    echo "            start-cn [namespace node_amf_spgwu] |"
    echo "            start-gnb [namespace node_gnb] |"
    echo "            start-ue [namespace node_gnb] |"
    echo "            stop-cn [namespace] |"
    echo "            stop-gnb [namespace] |"
    echo "            stop-ue [namespace] |"
    echo "            get-cn-pcap [namespace] |"
    echo "            get-ran-pcap [namespace] |"
    echo "            get-all-pcap [namespace]"
    exit 1
}


function get-all-logs() {
    ns=$1; shift
    prefix=$1; shift

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
    
}


function get-cn-pcap(){
    ns=$1; shift
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    AMF_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-amf,app.kubernetes.io/instance=oai-amf" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G CN pcap files from the AMF pod on ns $ns"
    echo "kubectl -c tcpdump -n $ns exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz pcap"
    kubectl -c tcpdump -n $ns exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz pcap || true
    echo "kubectl -c tcpdump cp $ns/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap.tgz"
    kubectl -c tcpdump cp $ns/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap-"$DATE".tgz || true
}


function get-ran-pcap(){
    ns=$1; shift
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    GNB_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G ran pcap file from the oai-gnb pod on ns $ns"
    echo "kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz ran-pcap.tgz pcap"
    kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz ran-pcap.tgz pcap || true
    echo "kubectl -c tcpdump cp $ns/$GNB_POD_NAME:ran-pcap.tgz $prefix/ran-pcap-"$DATE".tgz"
    kubectl -c tcpdump cp $ns/$GNB_POD_NAME:ran-pcap.tgz $prefix/ran-pcap-"$DATE".tgz || true
}


function get-all-pcap(){
    ns=$1; shift
    prefix=$1; shift

    get-cn-pcap $ns $prefix
    get-ran-pcap $ns $prefix
}



function configure-oai-5g-basic() {
    node_amf_spgwu=$1; shift
    pcap=$1; shift
    
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

    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/basic-r2lab.sed <<EOF
s|privileged:.*|privileged: $PRIVILEGED|
s|create: false|create: true|
s|n2IPadd:.*|n2IPadd: "$IP_AMF_N2"|
s|n2Netmask:.*|n2Netmask: "24"|
s|hostInterface:.*|hostInterface: "$IF_NAME_AMF_N2_SPGWU_N3" # interface of the nodes for amf/N2 and spgwu/N3|
s|amfInterfaceNameForNGAP:.*|amfInterfaceNameForNGAP: "net1" # If multus creation is true then net1 else eth0|
s|mcc:.*|mcc: "$MCC"|
s|mnc:.*|mnc: "$MNC"|
s|n3Ip:.*|n3Ip: "$IP_UPF_N3"|
s|n3Netmask:.*|n3Netmask: "24"|
s|n3If:.*|n3If: "net1"  # net1 if gNB is outside the cluster network and multus creation is true else eth0|
s|n6If:.*|n6If: "net1"  # net1 if gNB is outside the cluster network and multus creation is true else eth0  (important because it sends the traffic towards internet)|
s|dnsIpv4Address:.*|dnsIpv4Address: "138.96.0.210" # configure the dns for UE don't use Kubernetes DNS|
s|dnsSecIpv4Address:.*|dnsSecIpv4Address: "193.51.196.138" # configure the dns for UE don't use Kubernetes DNS|
s|dnn0:.*|dnn0: "$DNN"|
s|dnnNi0:.*|dnnNi0: "$DNN"|
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
--- oai_db-basic-orig.sql	2023-02-09 20:00:46.000000000 +0100
+++ oai_db-basic-new.sql	2023-02-11 15:33:19.000000000 +0100
@@ -150,31 +150,19 @@
 -- Dumping data for table `AuthenticationSubscription`
 --
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000100', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000100');
+('208950000000010', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '208950000000010');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000101', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000101');
+('208950000000011', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '208950000000011');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000102', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000102');
+('208950000000012', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '208950000000012');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000103', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000103');
+('208950000000013', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '208950000000013');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000104', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000104');
+('208950000000014', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '208950000000014');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000105', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000105');
+('208950000000015', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '208950000000015');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
-('001010000000106', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'C42449363BBAD02B66D16BC975D77CC1', NULL, NULL, NULL, NULL, '001010000000106');
-INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
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
+('$RFSIM_IMSI', '5G_AKA', '$FULL_KEY', '$FULL_KEY', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '$OPC', NULL, NULL, NULL, NULL, '$RFSIM_IMSI');
 
 
 -- --------------------------------------------------------
@@ -320,34 +308,24 @@
 -- AUTO_INCREMENT for dumped tables
 --
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000100', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.100\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('208950000000010', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.100\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
+('208950000000011', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.101\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000101', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.101\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('208950000000012', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.102\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000102', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.102\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('208950000000013', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.103\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000103', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.103\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('208950000000014', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.104\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000104', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.104\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('208950000000015', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.105\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES
-('001010000000105', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.105\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
+('$RFSIM_IMSI', '20895', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"$DNN\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 1,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.105\"}]},\"ims\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4V6\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 2,\"arp\":{\"priorityLevel\": 15,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
 
 -- Dynamic IPADDRESS Allocation
 
 INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
 ('001010000000106', '00101', '{\"sst\": 1, \"sd\": \"16777215\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"1000Mbps\", \"downlink\":\"1000Mbps\"}}}');
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
-
 
 --
 -- AUTO_INCREMENT for table `SdmSubscriptions`

EOF
    patch "$ORIG_CHART" < /tmp/oai_db-basic-patch
}


function configure-amf() {

    FUNCTION="oai-amf"
    DIR="$OAI5G_CORE/$FUNCTION"
    ORIG_CHART="$OAI5G_CORE/$FUNCTION"/templates/deployment.yaml
    echo "Configuring chart $ORIG_CHART for R2lab"

    cp "$ORIG_CHART" /tmp/"$FUNCTION"_deployment.yaml-orig
    perl -i -p0e 's/>-.*?\}]/"{{ .Chart.Name }}-n2-net1"/s' "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_deployment.yaml-orig "$ORIG_CHART"
}


function configure-spgwu-tiny() {

    FUNCTION="oai-spgwu-tiny"
    DIR="$OAI5G_CORE/$FUNCTION"
    ORIG_CHART="$OAI5G_CORE/$FUNCTION"/templates/deployment.yaml
    echo "Configuring chart $ORIG_CHART for R2lab"

    cp "$ORIG_CHART" /tmp/"$FUNCTION"_deployment.yaml-orig
    perl -i -p0e 's/>-.*?\}]/"{{ .Chart.Name }}-n3-net1"/s' "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_deployment.yaml-orig "$ORIG_CHART"
}


function configure-gnb() {
    node_gnb=$1; shift
    rru=$1; shift
    pcap=$1; shift
    

    # Prepare mounted.conf and gnb chart files
    echo "configure-gnb to run on node $node_gnb with RRU $rru and pcap is $pcap"
    echo "First prepare gNB mounted.conf and values/multus/configmap/deployment charts for $rru"

    DIR_GNB="/root/oai5g-rru/gnb-config"
    DIR_CONF="$DIR_GNB/conf"
    DIR_CHARTS="$DIR_GNB/charts"
    DIR_GNB_DEST="/root/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb"
    DIR_TEMPLATES="$DIR_GNB_DEST/templates"

    SED_CONF_FILE="/tmp/gnb_conf.sed"
    SED_VALUES_FILE="/tmp/$FUNCTION-r2lab.sed"
    
    if [[  "$rru" == "b210" ]]; then
	RRU_TYPE="b210"
	CONF_ORIG="$DIR_CONF/$CONF_B210"
    elif [[ "$rru" == "n300" || "$rru" == "n320" ]]; then
	if [[ "$rru" == "n300" ]]; then
	    SDR_ADDRS="$ADDRS_N300"
	elif [[ "$rru" == "n320" ]]; then
	    SDR_ADDRS="$ADDRS_N320"
	fi
	cat > "$SED_CONF_FILE" <<EOF
s|sdr_addrs =.*|sdr_addrs = "$SDR_ADDRS,clock_source=internal,time_source=internal"|
EOF
	cat > "$SED_VALUES_FILE" <<EOF
s|sfp1hostInterface:.*|sfp1hostInterface: "$IF_NAME_LOCAL_N3XX_1"|
s|sfp2hostInterface:.*|sfp2hostInterface: "$IF_NAME_LOCAL_N3XX_2"|
s|useAdditionalOptions:.*|useAdditionalOptions: "--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"|
EOF
	RRU_TYPE="n3xx"
	CONF_ORIG="$DIR_CONF/$CONF_N3XX"
    elif [[ "$rru" == "jaguar" || "$rru" == "panther" ]]; then
	RRU_TYPE="aw2s"
	if [[  "$rru" == "jaguar" ]]; then
	    CONF_AW2S="$CONF_JAGUAR"
	    ADDR_AW2S="$ADDR_JAGUAR"
	else
	    CONF_AW2S="$CONF_PANTHER"
	    ADDR_AW2S="$ADDR_PANTHER"
	fi
	cat > "$SED_CONF_FILE" <<EOF
s|local_if_name.*|local_if_name  = "net3"|
s|remote_address.*|remote_address = "$ADDR_AW2S"|
s|local_address.*|local_address = "$IP_GNB_AW2S"|
s|sdr_addrs =.*||
EOF
	cat >> "$SED_VALUES_FILE" <<EOF
s|aw2sIPadd:.*|aw2sIPadd: "$IP_GNB_AW2S"|
s|aw2shostInterface:.*|aw2shostInterface: "$IF_NAME_LOCAL_AW2S"|
s|useAdditionalOptions:.*|useAdditionalOptions: "--sa --thread-pool 1,3,5,7,9,11,13,15 --log_config.global_log_options level,nocolor,time"|
EOF
	CONF_ORIG="$DIR_CONF/$CONF_AW2S"
    elif [[ "$rru" == "rfsim" ]]; then
	echo "configure-gnb: rfsim mode used, use the default charts"
    else
	echo "Unknown rru selected: $rru"
	usage
    fi

    if [[ "$rru" != "rfsim" ]]; then
	echo "Copy the relevant chart files corresponding to $RRU_TYPE RRU"
	echo cp "$DIR_CHARTS"/values-"$RRU_TYPE".yaml "$DIR_GNB_DEST"/values.yaml
	cp "$DIR_CHARTS"/values-"$RRU_TYPE".yaml "$DIR_GNB_DEST"/values.yaml
	echo cp "$DIR_CHARTS"/deployment-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/deployment.yaml
	cp "$DIR_CHARTS"/deployment-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/deployment.yaml
	echo cp "$DIR_CHARTS"/multus-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/multus.yaml
	cp "$DIR_CHARTS"/multus-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/multus.yaml

	echo "Set up configmap.yaml chart with the right gNB configuration from $CONF_ORIG"
	# Keep the 17 first lines of configmap.yaml
	head -17  "$DIR_CHARTS"/configmap.yaml > /tmp/configmap.yaml
	# Add a 6-characters margin to gnb.conf
	awk '$0="      "$0' "$CONF_ORIG" > /tmp/gnb.conf
	# Append the modified gnb.conf to /tmp/configmap.yaml
	cat /tmp/gnb.conf >> /tmp/configmap.yaml
	echo -e "\n{{- end }}\n" >> /tmp/configmap.yaml
	mv /tmp/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml
    fi

    echo "First configure gnb.conf within configmap.yaml"
    # remove NSSAI sd info for PLMN and add other parameters for RUs 
    #s|sd = 0x010203|sd = 0x000001|
    cat >> "$SED_CONF_FILE" <<EOF
s|sd = 0x010203;||
s|, sd = 0x010203||
s|sd = 0x010203||
s|mcc = 208;|mcc = $MCC;|
s|mnc = [0-9][0-9];|mnc = $MNC;|
s|ipv4       =.*|ipv4       = "$IP_AMF_N2";|
s|GNB_INTERFACE_NAME_FOR_NG_AMF.*|GNB_INTERFACE_NAME_FOR_NG_AMF            = "net1";|
s|GNB_IPV4_ADDRESS_FOR_NG_AMF.*|GNB_IPV4_ADDRESS_FOR_NG_AMF              = "$IP_GNB_N2/24";|
s|GNB_INTERFACE_NAME_FOR_NGU.*|GNB_INTERFACE_NAME_FOR_NGU               = "net2";|
s|GNB_IPV4_ADDRESS_FOR_NGU.*|GNB_IPV4_ADDRESS_FOR_NGU                 = "$IP_GNB_N3/24";|
EOF
    cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
    sed -f "$SED_CONF_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
    echo "Display new $DIR_TEMPLATES/configmap.yaml"
    cat "$DIR_TEMPLATES"/configmap.yaml

    # Configure gnb values.yaml chart
    FUNCTION="oai-gnb"
    DIR="$OAI5G_RAN/$FUNCTION"
    ORIG_CHART="$DIR"/values.yaml

    echo "Then configure $ORIG_CHART of oai-gnb"
    if [[ $pcap == "True" ]]; then
	GENER_PCAP="true"
	SHARED_VOL="true"
    else
	GENER_PCAP="false"
	SHARED_VOL="false"
    fi
    if [[ "$rru" == "rfsim" ]]; then
	cat >> "$SED_VALUES_FILE" <<EOF
s|create: false|create: true|
s|tcpdump:.*|tcpdump: $GENER_PCAP|
s|n2n3IPadd:.*|n2n3IPadd: "$IP_GNB_N2N3"|
s|n2n3Netmask:.*|n2n3Netmask: "24"|
s|hostInterface:.*|hostInterface: "$IF_NAME_GNB_N2"|
s|mountConfig:.*|mountConfig: true|
s|mnc:.*|mnc: "$MNC"|
s|mcc:.*|mcc: "$MCC"|
s|gnbNgaIfName:.*|gnbNgaIfName: "net1"|
s|gnbNgaIpAddress:.*|gnbNgaIpAddress: "$IP_GNB_N2N3"|
s|gnbNguIpAddress:.*|gnbNguIpAddress: "$IP_GNB_N2N3"|
s|sdrAddrs:.*||
EOF
    else
	cat >> "$SED_VALUES_FILE" <<EOF
s|create: false|create: true|
s|tcpdump:.*|tcpdump: $GENER_PCAP|
s|n2IPadd:.*|n2IPadd: "$IP_GNB_N2"|
s|n2Netmask:.*|n2Netmask: "24"|
s|n2hostInterface:.*|n2hostInterface: "$IF_NAME_GNB_N2"|
s|n3IPadd:.*|n3IPadd: "$IP_GNB_N3"|
s|n3Netmask:.*|n3Netmask: "24"|
s|n3hostInterface:.*|n3hostInterface: "$IF_NAME_GNB_N3"|
s|sharedvolume:.*|sharedvolume: $SHARED_VOL|
s|nodeName:.*|nodeName: $node_gnb|
EOF
    fi
    cp "$ORIG_CHART" /tmp/"$FUNCTION"_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_VALUES_FILE" < /tmp/"$FUNCTION"_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_values.yaml-orig "$ORIG_CHART"
}


function configure-oai-nr-ue() {
    fit_ue=$1; shift
    
    FUNCTION="oai-nr-ue"
    DIR="$OAI5G_RAN/$FUNCTION"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="/tmp/$FUNCTION-r2lab.sed"
    echo "Configuring chart $ORIG_CHART for R2lab"
    cat > "$SED_FILE" <<EOF
s|create: false|create: true|
s|ipadd:.*|ipadd: "$IP_NRUE"|
s|netmask:.*|netmask: "24"|
s|hostInterface:.*|hostInterface: "$IF_NAME_NRUE"|
s|fullImsi:.*|fullImsi: "$RFSIM_IMSI"|
s|fullKey:.*|fullKey: "$FULL_KEY"|
s|opc:.*|opc: "$OPC"|
s|dnn:.*|dnn: "$DNN"|
s|nssaiSst:.*|nssaiSst: "1"|
s|nssaiSd:.*|nssaiSd: "16777215"|
s|nodeName:.*|nodeName:|
EOF

    cp "$ORIG_CHART" /tmp/"$FUNCTION"_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < /tmp/"$FUNCTION"_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_values.yaml-orig "$ORIG_CHART"

    ORIG_CHART="$DIR"/templates/deployment.yaml
    echo "Configuring chart $ORIG_CHART for R2lab"

    cp "$ORIG_CHART" /tmp/"$FUNCTION"_deployment.yaml-orig
    perl -i -p0e 's/>-.*?\}]/"{{ .Chart.Name }}-net1"/s' "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_deployment.yaml-orig "$ORIG_CHART"
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

    configure-oai-5g-basic $node_amf_spgwu $pcap
    configure-mysql
    configure-amf
    configure-spgwu-tiny
    configure-gnb $node_gnb $rru $pcap
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
    helm plugin install https://github.com/ThalesGroup/helm-spray || true

    # Install patch command...
    dnf -y install patch

    # Just in case the k8s cluster has been restarted without multus enabled..
    echo "kube-install.sh enable-multus"
    kube-install.sh enable-multus || true
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

    echo "Running start-gnb() with namespace: $ns, node_gnb:$node_gnb"

    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    echo "helm -n$ns install oai-gnb oai-gnb/"
    helm -n$ns install oai-gnb oai-gnb/

    echo "Wait until the gNB pod is READY"
    echo "kubectl -n$ns wait pod --for=condition=Ready --all"
    kubectl -n$ns wait pod --for=condition=Ready --all
}


function start-ue() {
    ns=$1
    shift
    node_gnb=$1
    shift

    echo "Running start-ue() on namespace: $ns, node_gnb:$node_gnb"

    echo "cd $OAI5G_RAN"
    cd "$OAI5G_RAN"

    # Retrieve the IP address of the gnb pod and set it
    GNB_POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-gnb -o jsonpath="{.items[0].metadata.name}")
    GNB_POD_IP=$(kubectl -n$ns get pod $GNB_POD_NAME --template '{{.status.podIP}}')
    echo "gNB pod IP is $GNB_POD_IP"
    conf_ue_dir="$OAI5G_RAN/oai-nr-ue"
    cat >/tmp/gnb-values.sed <<EOF
s|  rfSimulator:.*|  rfSimulator: "${GNB_POD_IP}"|
EOF

    echo "(Over)writing oai-nr-ue chart $conf_ue_dir/values.yaml"
    cp $conf_ue_dir/values.yaml /tmp/values-orig.yaml
    sed -f /tmp/gnb-values.sed </tmp/values-orig.yaml >/tmp/values.yaml
    cp /tmp/values.yaml $conf_ue_dir/

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
    pcap=$1; shift

    echo "start: run all oai5g pods on namespace: $ns"

    if [[ $pcap == "True" ]]; then
	echo "start: Create a k8s persistence volume for generation of pcap files"
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

	
	echo "start: Create a k8s persistent volume claim for pcap files"
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

    start-cn $ns $node_amf_spgwu
    start-gnb $ns $node_gnb

    if [[ "$rru" == "rfsim" ]]; then
	start-nr-ue $ns $node_gnb
    fi

    echo "****************************************************************************"
    echo "When you finish, to clean-up the k8s cluster, please run demo-oai.py --clean"
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


function stop-ue(){
    ns=$1
    shift

    echo "helm -n$ns uninstall oai-nr-ue"
    helm -n$ns uninstall oai-nr-ue
}


function stop() {
    ns=$1; shift
    rru=$1; shift
    pcap=$1; shift

    echo "Running stop() on namespace:$ns; pcap is $pcap"

    if [[ $pcap == "True" ]]; then
	prefix=${PREFIX_STATS-"/tmp/oai5g-stats"}
	echo "First retrieve all pcap and log files in $prefix and compressed it"
	mkdir -p $prefix
	echo "cleanup $prefix before including new logs/pcap files"
	cd $prefix; rm -f *.pcap *.tgz *.logs
	get-all-pcap $ns $prefix
	get-all-logs $ns $prefix
	cd /tmp; dirname=$(basename $prefix)
	echo tar cfz "$dirname".tgz $dirname
	tar cfz "$dirname".tgz $dirname
    fi

    res=$(helm -n $ns ls | wc -l)
    if test $res -gt 1; then
        echo "Remove all 5G OAI pods"
	stop-cn $ns
	stop-gnb $ns
	if [[ "$rru" == "rfsim" ]]; then
	    stop-ue $ns
	fi
    else
        echo "OAI5G demo is not running, there is no pod on namespace $ns !"
    fi

    echo "Wait until all $ns pods disppear"
    kubectl delete pods -n $ns --all --wait --cascade=foreground

    if [[ $pcap == "True" ]]; then
	echo "Delete k8s persistence volume / claim for pcap files"
	kubectl -n $ns delete pvc cn5g-pvc || true
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
        if test $# -eq 6; then
            start $2 $3 $4 $5 $6
        elif test $# -eq 1; then
	    start $DEF_NS $DEF_NODE_AMF_SPGWU $DEF_NODE_GNB $DEF_RRU $DEF_PCAP
	else
            usage
        fi
    elif [ "$1" == "stop" ]; then
        if test $# -eq 4; then
            stop $2 $3 $4
        elif test $# -eq 1; then
	    stop $DEF_NS $DEF_RRU $DEF_PCAP
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
        if test $# -eq 3; then
            start-gnb $2 $3
        elif test $# -eq 1; then
	    start-gnb $DEF_NS $DEF_NODE_GNB
	else
            usage
        fi
    elif [ "$1" == "start-ue" ]; then
        if test $# -eq 3; then
            start-ue $2 $3
        elif test $# -eq 1; then
	    start-ue $DEF_NS $DEF_NODE_GNB
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
    elif [ "$1" == "stop-ue" ]; then
        if test $# -eq 2; then
            stop-ue $2
        elif test $# -eq 1; then
	    stop-ue $DEF_NS
	else
            usage
        fi
    elif [ "$1" == "get-cn-pcap" ]; then
        if test $# -eq 2; then
            get-cn-pcap $2
        elif test $# -eq 1; then
	    get-cn-pcap $DEF_NS
	else
            usage
        fi
    elif [ "$1" == "get-ran-pcap" ]; then
        if test $# -eq 2; then
            get-ran-pcap $2
        elif test $# -eq 1; then
	    get-ran-pcap $DEF_NS
	else
            usage
        fi
    elif [ "$1" == "get-all-pcap" ]; then
        if test $# -eq 2; then
            get-all-pcap $2
        elif test $# -eq 1; then
	    get-all-pcap $DEF_NS
	else
            usage
        fi
    else
        usage
    fi
fi
