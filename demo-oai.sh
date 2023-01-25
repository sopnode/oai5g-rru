#!/bin/bash

# Default k8s namespace and gNB node running oai5g pod
DEF_NS="oai5g"
#DEF_NODE_AMF_SPGWU="sopnode-w1.inria.fr" 
DEF_NODE_AMF_SPGWU="sopnode-w3.inria.fr" # AMF pod will run on the same host than the one for SPGWU pod
#DEF_NODE_GNB="sopnode-l1.inria.fr"
DEF_NODE_GNB="sopnode-w2.inria.fr"
DEF_RRU="n300" # Choose between "n300", "n320", "jaguar" and "panther"
DEF_PCAP="False"

PREFIX_STATS="/tmp/oai5g-stats"

# IP Pod addresses
P100="192.168.100"
IP_AMF_N1="$P100.241"
IP_UPF_N3="$P100.242"
IP_GNB_N2="$P100.243"
IP_GNB_N3="$P100.244"
IP_GNB_AW2S="$P100.245" 

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
IF_NAME_GNB_N2_N3="$IF_NAME_VLAN100"
IF_NAME_LOCAL_AW2S="$IF_NAME_VLAN100"
IF_NAME_LOCAL_N3XX_1="$IF_NAME_VLAN10"
IF_NAME_LOCAL_N3XX_2="$IF_NAME_VLAN20"

# gNB conf file for RRU devices
CONF_AW2S="gnb.sa-rru-50MHz-2x2.conf"
CONF_N3XX="gnb.sa.band66.fr1.106PRB.usrpn300.conf"

OAI5G_CHARTS="$HOME"/oai-cn5g-fed/charts
OAI5G_CORE="$OAI5G_CHARTS"/oai-5g-core
OAI5G_BASIC="$OAI5G_CORE"/oai-5g-basic
OAI5G_RAN="$OAI5G_CHARTS"/oai-5g-ran
OAI5G_AMF="$OAI5G_CORE"/oai-amf
OAI5G_AUSF="$OAI5G_CORE"/oai-ausf
OAI5G_SMF="$OAI5G_CORE"/oai-smf
OAI5G_SPGWU="$OAI5G_CORE"/oai-spgwu-tiny

# Other CN parameters configuration
MCC="208"
MNC="95"

function usage() {
    echo "USAGE:"
    echo "demo-oai.sh init [namespace rru pcap] |"
    echo "            start [namespace node_amf_spgwu node_gnb pcap] |"
    echo "            stop [namespace pcap] |"
    echo "            configure-all [node_amf_spgwu node_gnb rru pcap] |"
    echo "            reconfigure [node_amf_spgwu node_gnb] |"
    echo "            start-cn [namespace node_amf_spgwu] |"
    echo "            start-gnb [namespace node_gnb] |"
    echo "            stop-cn [namespace] |"
    echo "            stop-gnb [namespace] |"
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
    echo "Retrieve OAI5G cn pcap files from oai-amf pod, ns $ns"
    echo "kubectl -c tcpdump -n $ns exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz pcap"
    kubectl -c tcpdump -n $ns exec -i $AMF_POD_NAME -- /bin/tar cfz cn-pcap.tgz pcap
    echo "kubectl -c tcpdump cp $ns/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap.tgz"
    kubectl -c tcpdump cp $ns/$AMF_POD_NAME:cn-pcap.tgz $prefix/cn-pcap-"$DATE".tgz
}


function get-ran-pcap(){
    ns=$1; shift
    prefix=$1; shift

    DATE=`date +"%Y-%m-%dT%H.%M.%S"`

    GNB_POD_NAME=$(kubectl get pods --namespace $ns -l "app.kubernetes.io/name=oai-gnb,app.kubernetes.io/instance=oai-gnb" -o jsonpath="{.items[0].metadata.name}")
    echo "Retrieve OAI5G ran pcap files from oai-gnb pod, ns $ns"
    echo "kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz ran-net1-pcap.tgz pcap"
    kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz ran-net1-pcap.tgz pcap
    echo "kubectl -c tcpdump cp $ns/$GNB_POD_NAME:ran-net1-pcap.tgz $prefix/ran-net1-pcap-"$DATE".tgz"
    kubectl -c tcpdump cp $ns/$GNB_POD_NAME:ran-net1-pcap.tgz $prefix/ran-net1-pcap-"$DATE".tgz
    echo "kubectl -c tcpdump2 -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz ran-net2-pcap.tgz pcap"
    kubectl -c tcpdump -n $ns exec -i $GNB_POD_NAME -- /bin/tar cfz ran-net2-pcap.tgz pcap
    echo "kubectl -c tcpdump cp $ns/$GNB_POD_NAME:ran-net2-pcap.tgz $prefix/ran-net2-pcap-"$DATE".tgz"
    kubectl -c tcpdump cp $ns/$GNB_POD_NAME:ran-net2-pcap.tgz $prefix/ran-net2-pcap-"$DATE".tgz
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
    
    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/basic-r2lab.sed <<EOF
s|create: false|create: true|
s|n1IPadd:.*|n1IPadd: "$IP_AMF_N1"|
s|n1Netmask:.*|n1Netmask: "24"|
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
EOF

    cp "$OAI5G_BASIC"/values.yaml /tmp/basic_values.yaml-orig
    echo "(Over)writing $OAI5G_BASIC/values.yaml"
    sed -f /tmp/basic-r2lab.sed < /tmp/basic_values.yaml-orig > "$OAI5G_BASIC"/values.yaml
    perl -i -p0e "s/nodeSelector: \{\}\noai-smf:/nodeName: \"$node_amf_spgwu\"\n  nodeSelector: \{\}\noai-smf:/s" "$OAI5G_BASIC"/values.yaml
    perl -i -p0e "s/nodeSelector: \{\}\noai-spgwu-tiny:/nodeName: \"$node_amf_spgwu\"\n  nodeSelector: \{\}\noai-spgwu-tiny:/s" "$OAI5G_BASIC"/values.yaml

    diff /tmp/basic_values.yaml-orig "$OAI5G_BASIC"/values.yaml
    
    if [[ $pcap == "True" ]]; then
	echo "Modify CN charts to generate pcap files"
    cat > /tmp/pcap.sed <<EOF
s|tcpdump:.*|tcpdump: true|
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
    fi

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
--- oai_db-basic.sql	2022-09-16 17:18:26.491178530 +0200
+++ new.sql	2022-09-16 17:31:36.091401829 +0200
@@ -191,7 +191,40 @@
 ('208990100001139', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'c42449363bbad02b66d16bc975d77cc1', NULL, NULL, NULL, NULL, '208990100001139');
 INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
 ('208990100001140', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', 'c42449363bbad02b66d16bc975d77cc1', NULL, NULL, NULL, NULL, '208990100001140');
-
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000001', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000001');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000002', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000002');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000003', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000003');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000004', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000004');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000005', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000005');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000006', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000006');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000007', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000007');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000008', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000008');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000009', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000009');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000010', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000010');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000011', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000011');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000012', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000012');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000013', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000013');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000014', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000014');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000015', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000015');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950000000016', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950000000016');
+INSERT INTO `AuthenticationSubscription` (`ueid`, `authenticationMethod`, `encPermanentKey`, `protectionParameterId`, `sequenceNumber`, `authenticationManagementField`, `algorithmId`, `encOpcKey`, `encTopcKey`, `vectorGenerationInHss`, `n5gcAuthMethod`, `rgAuthenticationInd`, `supi`) VALUES
+('208950100001121', '5G_AKA', 'fec86ba6eb707ed08905757b1bb44b8f', 'fec86ba6eb707ed08905757b1bb44b8f', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '8e27b6af0e692e750f32667a3b14605d', NULL, NULL, NULL, NULL, '208950100001121');
 
 
 
@@ -241,6 +274,9 @@
   `suggestedPacketNumDlList` json DEFAULT NULL,
   `3gppChargingCharacteristics` varchar(50) DEFAULT NULL
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
+INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
+('208950100001121', '20895', '{\"sst\": 1, \"sd\": \"1\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"100Mbps\", \"downlink\":\"100Mbps\"}}}');
+
 
 -- --------------------------------------------------------
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
    
    FUNCTION="oai-gnb"
    DIR="$OAI5G_RAN/$FUNCTION"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="/tmp/$FUNCTION-r2lab.sed"

    # Tune values.yaml chart
    echo "Configuring chart $ORIG_CHART for R2lab"
    cat > "$SED_FILE" <<EOF
s|tcpdump:.*|tcpdump: $GENER_PCAP|
s|n2IPadd:.*|n2IPadd: "$IP_GNB_N2"|
s|n2Netmask:.*|n2Netmask: "24"|
s|n3IPadd:.*|n3IPadd: "$IP_GNB_N3"|
s|n3Netmash:.*|n3Netmask: "24"|
s|hostInterface:.*|hostInterface: "$IF_NAME_GNB_N2_N3"|
s|gnbName:.*|gnbName: "$rru"|
s|mcc:.*|mcc: "$MCC"|
s|mnc:.*|mnc: "$MNC"|
s|amfIpAddress:.*|amfIpAddress: "$IP_AMF_N1"|
s|gnbNgaIfName:.*|gnbNgaIfName: "net1"|
s|gnbNgaIpAddress:.*|gnbNgaIpAddress: "$IP_GNB_N2"|
s|gnbNguIfName:.*|gnbNguIfName: "net2"|
s|gnbNguIpAddress:.*|gnbNguIpAddress: "$IP_GNB_N3"|
s|sharedvolume:.*|sharedvolume: $SHARED_VOL|
s|nodeName:.*|nodeName: $node_gnb|
EOF

    if [[ $pcap == "True" ]]; then
	GENER_PCAP="true"
	SHARED_VOL="true"
    else
	GENER_PCAP="false"
	SHARED_VOL="false"
    fi
    if [[ "$rru" == "n300" || "$rru" == "n320" ]]; then
	if [[ "$rru" == "n300" ]]; then
	    SDR_ADDRS="$ADDRS_N300"
	elif [["$rru" == "n320" ]]; then
	    SDR_ADDRS="$ADDRS_N320"
	fi
	cat >> "$SED_FILE" <<EOF
s|sfp1hostInterface:.*|sfp1hostInterface: "$IF_NAME_LOCAL_N3XX_1"|
s|sfp2hostInterface:.*|sfp2hostInterface: "$IF_NAME_LOCAL_N3XX_2"|
s|useAdditionalOptions:.*|useAdditionalOptions: "--sa --usrp-tx-thread-config 1 --tune-offset 30000000 --thread-pool 1,3,5,7,9,11,13,15"|
s|sdrAddrs:.*|sdrAddrs: "$SDR_ADDRS,clock_source=internal,time_source=internal"|
EOF
    elif [[ "$rru" == "jaguar" || "$rru" == "panther" ]]; then
	if [ "$rru" == "jaguar" ] ; then
	    ADDR_AW2S="$ADDR_JAGUAR"
	elif [ "$rru" == "panther" ] ; then
	    ADDR_AW2S="$ADDR_PANTHER"
	fi
	cat >> "$SED_FILE" <<EOF
s|aw2sIPadd:.*|aw2sIPadd: "$IP_GNB_AW2S"|
s|aw2shostInterface:.*|aw2shostInterface: "$IF_NAME_LOCAL_AW2S"|
s|useAdditionalOptions:.*|useAdditionalOptions: "--sa --tune-offset 30000000 --thread-pool 1,3,5,7,9,11,13,15"|
s|remoteAddr.*|remoteAddr: "$ADDR_AW2S"| 
s|localAddr.*|localAddr: "$IP_GNB_AW2S"|
EOF
    else
        echo "Unknown rru selected: $rru"
        usage
    fi
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

    echo "Applying SophiaNode patches to OAI5G located on "$HOME"/oai-cn5g-fed"
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
    rru=$1; shift
    pcap=$1; shift

    # init function should be run once per demo.
    echo "init: ensure spray is installed and possibly create secret docker-registry"
    # Remove pulling limitations from docker-hub with anonymous account
    kubectl create namespace $ns || true
    kubectl -n$ns delete secret regcred || true
    kubectl -n$ns create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=r2labuser --docker-password=r2labuser-pwd --docker-email=r2labuser@turletti.com || true

    # Ensure that helm spray plugin is installed
    helm plugin install https://github.com/ThalesGroup/helm-spray || true

    # Install patch command...
    dnf -y install patch

    # Just in case the k8s cluster has been restarted without multus enabled..
    echo "kube-install.sh enable-multus"
    kube-install.sh enable-multus || true

    if [[ $pcap == "True" ]]; then
	echo "Create k8s persistence volumes for pcap files"
	cd /root/oai5g-rru/k8s-pv
	./create-pv.sh $ns
    fi

    # Prepare mounted.conf and gnb chart files
    echo "Preparing gNB mounted.conf and values/multus/configmap/deployment charts for $rru"

    DIR_GNB="/root/oai5g-rru/gnb-config"
    DIR_CONF="$DIR_GNB/conf"
    DIR_CHARTS="$DIR_GNB/charts"
    DIR_GNB_DEST="/root/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb"
    DIR_TEMPLATES="$DIR_GNB_DEST/templates"

    if [[ "$rru" == "n300" || "$rru" == "n320" ]]; then
	RRU_TYPE="n3xx"
	CONF_ORIG="$DIR_CONF/$CONF_N3XX"
    elif [[ "$rru" == "jaguar" || "$rru" == "panther" ]]; then
	RRU_TYPE="aw2s"
	CONF_ORIG="$DIR_CONF/$CONF_AW2S"
    else
	echo "Unknown rru selected: $rru"
	usage
    fi
    
    echo "Copying the right chart files corresponding to $RRU_TYPE RRU"
    echo cp "$DIR_CHARTS"/values-"$RRU_TYPE".yaml "$DIR_GNB_DEST"/values.yaml
    cp "$DIR_CHARTS"/values-"$RRU_TYPE".yaml "$DIR_GNB_DEST"/values.yaml
    echo cp "$DIR_CHARTS"/deployment-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/deployment.yaml
    cp "$DIR_CHARTS"/deployment-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/deployment.yaml
    echo cp "$DIR_CHARTS"/multus-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/multus.yaml
    cp "$DIR_CHARTS"/multus-"$RRU_TYPE".yaml "$DIR_TEMPLATES"/multus.yaml

    echo "Preparing configmap.yaml chart that includes the right gNB configuration"
    head -17  "$DIR_CHARTS"/configmap.yaml > /tmp/configmap.yaml
    cat "$CONF_ORIG" >> /tmp/configmap.yaml
    echo -e "\n{{- end }}\n" >> /tmp/configmap.yaml
    mv /tmp/configmap.yaml "$DIR_TEMPLATES"/configmap.yaml

    # add NSSAI sd info for PLMN and sdr_addrs for RUs 
    SED_FILE="/tmp/gnb_conf.sed"
    cat > "$SED_FILE" <<EOF
s|sst = 1|sst = 1; sd = 0x1 |
s|mnc = 99;|mnc = 95;|
s|ipv4       =.*|ipv4       = "$IP_AMF_N1";|
s|GNB_INTERFACE_NAME_FOR_NG_AMF.*|GNB_INTERFACE_NAME_FOR_NG_AMF            = "net1";|
s|GNB_IPV4_ADDRESS_FOR_NG_AMF.*|GNB_IPV4_ADDRESS_FOR_NG_AMF              = "$IP_GNB_N2/24";|
s|GNB_INTERFACE_NAME_FOR_NGU.*|GNB_INTERFACE_NAME_FOR_NGU               = "net2";|
s|GNB_IPV4_ADDRESS_FOR_NGU.*|GNB_IPV4_ADDRESS_FOR_NGU                 = "$IP_GNB_N3/24";|
s|sdr_addrs =.*||
EOF
    cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
    sed -f "$SED_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml

    # set SDR IP ADDRESSES
    if [[ "$rru" == "n300" || "$rru" == "n320" ]] ; then
        perl -i -p0e "s/#clock_src = \"internal\";/#clock_src = \"internal\";\n  sdr_addrs = \"$SDR_ADDRS,clock_source=internal,time_source=internal\";/s" "$DIR_TEMPLATES"/configmap.yaml
    else
	SED_FILE="/tmp/aw2s_conf.sed"
	cat > "$SED_FILE" <<EOF
s|local_if_name.*|local_if_name  = "net3"|
s|remote_address.*|remote_address = "$ADDR_AW2S"|
s|local_address.*|local_address = "$IP_GNB_AW2S"|
EOF
	cp "$DIR_TEMPLATES"/configmap.yaml /tmp/configmap.yaml
	sed -f "$SED_FILE" < /tmp/configmap.yaml > "$DIR_TEMPLATES"/configmap.yaml
    fi
    # show changes applied to default conf
    echo "Display new $DIR_TEMPLATES/configmap.yaml"
    cat "$DIR_TEMPLATES"/configmap.yaml
}

function reconfigure() {
    node_amf_spgwu=$1
    shift
    node_gnb=$1
    shift

    echo "setup: Reconfigure oai5g charts from original ones"
    cd "$HOME"
    rm -rf oai-cn5g-fed
    git clone -b master https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed
    configure $node_amf_spgwu $node_gnb 
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

function start() {
    ns=$1; shift
    node_amf_spgwu=$1; shift
    node_gnb=$1; shift
    pcap=$1; shift

    echo "start: run all oai5g pods on namespace: $ns"

    # Check if all FIT nodes are ready
    while :; do
        kubectl wait no --for=condition=Ready $node_gnb && break
        clear
        echo "Wait until gNB FIT node is in READY state"
        kubectl get no
        sleep 5
    done

    if [[ $pcap == "True" ]]; then
	echo "Create k8s persistence volume claims for pcap files"
	cd /root/oai5g-rru/k8s-pv
	./create-pvc.sh $ns
    fi

    start-cn $ns $node_amf_spgwu
    start-gnb $ns $node_gnb

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


function stop() {
    ns=$1; shift
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
    else
        echo "OAI5G demo is not running, there is no pod on namespace $ns !"
    fi

    echo "Wait until all $ns pods disppear"
    kubectl delete pods -n $ns --all --wait --cascade=foreground

    if [[ $pcap == "True" ]]; then
	echo "Delete k8s persistence volume claims for pcap files"
	cd /root/oai5g-rru/k8s-pv
	./delete-pvc.sh $ns
    fi
#    echo "Delete namespace $ns"
#    echo "kubectl delete ns $ns"
#    kubectl delete ns $ns || true
}



#Handle the different function calls with or without input parameters
if test $# -lt 1; then
    usage
else
    if [ "$1" == "init" ]; then
        if test $# -eq 4; then
            init $2 $3 $4
        elif test $# -eq 1; then
	    init $DEF_NS $DEF_RRU $DEF_PCAP
        else
            usage
        fi
    elif [ "$1" == "start" ]; then
        if test $# -eq 5; then
            start $2 $3 $4 $5
        elif test $# -eq 1; then
	    start $DEF_NS $DEF_NODE_AMF_SPGWU $DEF_NODE_GNB $DEF_PCAP
	else
            usage
        fi
    elif [ "$1" == "stop" ]; then
        if test $# -eq 3; then
            stop $2 $3
        elif test $# -eq 1; then
	    stop $DEF_NS $DEF_PCAP
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
    elif [ "$1" == "reconfigure" ]; then
        if test $# -eq 3; then
            reconfigure $2 $3
        elif test $# -eq 1; then
	    reconfigure $DEF_NODE_AMF_SPGWU $DEF_NODE_GNB
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
