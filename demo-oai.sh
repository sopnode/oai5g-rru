#!/bin/bash

# Default k8s namespace and gNB node running oai5g pod
DEF_NS="oai5g"
DEF_NODE_SPGWU="sopnode-w3.inria.fr"
DEF_NODE_GNB="sopnode-w2.inria.fr"
DEF_RRU="n300"

# IP addresses of RRU devices
ADDRS_N300="addr=192.168.10.129,second_addr=192.168.20.129,mgmt_addr=192.168.3.151"
ADDRS_N320="addr=192.168.10.130,second_addr=192.168.20.130,mgmt_addr=192.168.3.152"
LOC_IF_NAME_AW2S="team0"
LOC_ADDR_AW2S="TBD"
ADDR_JAGUAR="TBD"
ADDR_PANTHER="TBD"

# gNB conf file for RRU devices
CONF_AW2S="gnb.sa-rru-50MHz-2x2.conf"
CONF_N3XX="gnb.sa.band66.fr1.106PRB.usrpn300.conf"

OAI5G_CHARTS="$HOME"/oai-cn5g-fed/charts
OAI5G_CORE="$OAI5G_CHARTS"/oai-5g-core
OAI5G_BASIC="$OAI5G_CORE"/oai-5g-basic
OAI5G_RAN="$OAI5G_CHARTS"/oai-5g-ran


function usage() {
    echo "USAGE:"
    echo "demo-oai.sh init [namespace rru] |"
    echo "            start [namespace node_spgwu node_gnb] |"
    echo "            stop [namespace] |"
    echo "            configure-all [node_spgwu node_gnb] |"
    echo "            reconfigure [node_spgwu node_gnb] |"
    echo "            start-cn [namespace node_spgwu] |"
    echo "            start-gnb [namespace node_gnb] |"
    echo "            stop-cn [namespace] |"
    echo "            stop-gnb [namespace] |"
    exit 1
}


function configure-oai-5g-basic() {
    node_spgwu=$1; shift
    
    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/basic-r2lab.sed <<EOF
s|create: false|create: true|
s|n1IPadd:.*|n1IPadd: "192.168.100.161"|
s|n1Netmask:.*|n1Netmask: "24"|
s|hostInterface:.*|hostInterface: "team0" # interface of the node (sopnode-w3) running amf pod for N2|
s|amfInterfaceNameForNGAP: "eth0" # If multus creation is true then net1 else eth0|amfInterfaceNameForNGAP: "net1" # If multus creation is true then net1 else eth0|
s|mnc: "99".*|mnc: "95"|
s|servedGuamiMnc0: "99"|servedGuamiMnc0: "95"|
s|plmnSupportMnc: "99"|plmnSupportMnc: "95"|
s|operatorKey:.*|operatorKey: "8e27b6af0e692e750f32667a3b14605d"  # should be same as in subscriber database|  
s|n3Ip:.*|n3Ip: "192.168.100.162"|
s|n3Netmask:.*|n3Netmask: "24"|
s|hostInterface:.*|hostInterface: "team0" # interface of the node (sopnode-w3) running spgwu pod for N3|
s|sgwS1uIf: "eth0"  # n3 interface, net1 if gNB is outside the cluster network and multus creation is true else eth0|sgwS1uIf: "net1"  # n3 interface, net1 if gNB is outside the cluster network and multus creation is true else eth0|
s|pgwSgiIf: "eth0"  # net1 if gNB is outside the cluster network and multus creation is true else eth0 (important because it sends the traffic towards internet)|pgwSgiIf: "eth0"  # net1 if gNB is outside the cluster network and multus creation is true else eth0 (important because it sends the traffic towards internet)|
s|dnsIpv4Address: "172.21.3.100" # configure the dns for UE don't use Kubernetes DNS|dnsIpv4Address: "138.96.0.210" # configure the dns for UE don't use Kubernetes DNS|
s|dnsSecIpv4Address: "172.21.3.100" # configure the dns for UE don't use Kubernetes DNS|dnsSecIpv4Address: "193.51.196.138" # configure the dns for UE don't use Kubernetes DNS|
s|sst0:.*|sst0: "1"|
s|sd0:.*|sd0: "1"|
s|sst1:.*|sst1: "1"|
s|sd1:.*|sd1: "10203"|
s|sst2:.*|sst2: "4"|
s|sd2:.*|sd2: "4"|
s|nssaiSst0:.*|nssaiSst0: 1|
s|nssaiSd0:.*|nssaiSd0: 1|
s|nssaiSst1:.*|nssaiSst1: 1|
s|nssaiSd1:.*|nssaiSd1: 10203|
s|nssaiSst2:.*|nssaiSst2: 4|
s|nssaiSd2:.*|nssaiSd2: 4|
EOF

    cp "$OAI5G_BASIC"/values.yaml /tmp/basic_values.yaml-orig
    echo "(Over)writing $OAI5G_BASIC/values.yaml"
    sed -f /tmp/basic-r2lab.sed < /tmp/basic_values.yaml-orig > "$OAI5G_BASIC"/values.yaml
    perl -i -p0e "s/nodeSelector: \{\}\noai-smf:/nodeName: \"$node_spgwu\"\n  nodeSelector: \{\}\noai-smf:/s" "$OAI5G_BASIC"/values.yaml

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
+('208950100001121', '20895', '{\"sst\": 1, \"sd\": \"10203\"}','{\"oai\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"100Mbps\", \"downlink\":\"100Mbps\"}}}');
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
    perl -i -p0e 's/>-.*?\}]/"{{ .Chart.Name }}-n1-net1"/s' "$ORIG_CHART"
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
    
    FUNCTION="oai-gnb"
    DIR="$OAI5G_RAN/$FUNCTION"
    ORIG_CHART="$DIR"/values.yaml
    SED_FILE="/tmp/$FUNCTION-r2lab.sed"

    # Tune values.yaml chart
    echo "Configuring chart $ORIG_CHART for R2lab"
    cat > "$SED_FILE" <<EOF
s|nodeName:.*|nodeName: $node_gnb|
EOF
    cp "$ORIG_CHART" /tmp/"$FUNCTION"_values.yaml-orig
    echo "(Over)writing $DIR/values.yaml"
    sed -f "$SED_FILE" < /tmp/"$FUNCTION"_values.yaml-orig > "$ORIG_CHART"
    diff /tmp/"$FUNCTION"_values.yaml-orig "$ORIG_CHART"
}


function configure-all() {
    node_spgwu=$1
    shift
    node_gnb=$1
    shift

    echo "Applying SopNode patches to OAI5G located on "$HOME"/oai-cn5g-fed"
    echo -e "\t with oai-spgwu-tiny running on $node_spgwu"
    echo -e "\t with oai-gnb running on $node_gnb"

    configure-oai-5g-basic $node_spgwu
    configure-mysql
    configure-amf
    configure-spgwu-tiny
    configure-gnb $node_gnb
}


function init() {
    ns=$1
    shift
    rru=$1
    shift

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

    # Configure gnb conf file
    echo "Configuring gNB conf for $rru"
    DIR_ORIG="/root/oai5g-rfsim/gnb-config/originals/"
    DIR_DEST="/root/oai-cn5g-fed/charts/oai-5g-ran/oai-gnb/conf/"
    if [[ "$rru" == "n300" || "$rru" == "n320" ]]; then
	CONF_ORIG="$DIR_ORIG/$CONF_N3XX"
	REPO_GNB="$REPO_GNB_N3XX"
	V_REPO_GNB="$V_REPO_GNB_N3XX"
	cp "$CONF_ORIG" "$DIR_DEST"/mounted.conf
	if [ "$rru" == "n300" ] ; then
	   SDR_ADDRS="$ADDRS_N300"
	elif [ "$rru" == "n320" ] ; then
	   SDR_ADDRS="$ADDRS_N300"
	fi
    elif [[ "$rru" == "jaguar" || "$rru" == "panther" ]]; then
	CONF_ORIG="$DIR_ORIG/$CONF_AW2S"
	REPO_GNB="$REPO_GNB_AW2S"
	V_REPO_GNB="$V_REPO_GNB_AW2S"
	cp "$CONF_ORIG" "$DIR_DEST"/mounted.conf
	if [ "$rru" == "jaguar" ] ; then
	    ADDR_AW2S="$ADDR_JAGUAR"
	elif [ "$rru" == "panther" ] ; then
	    ADDR_AW2S="$ADDR_PANTHER"
	fi
    else
	echo "Unknown rru selected: $rru"
	usage
    fi
    # add NSSAI sd info for PLMN and sdr_addrs for RUs 
    SED_FILE="/tmp/gnb_conf.sed"
    cat > "$SED_FILE" <<EOF
s|sst =.*|sst = 1; sd = 0x1; }) });|
s|mnc = 99;|mnc = 95;|
s|ipv4       =.*|ipv4       = "192.168.100.161";|
s|GNB_INTERFACE_NAME_FOR_NG_AMF.*|GNB_INTERFACE_NAME_FOR_NG_AMF            = "net1";|
s|GNB_IPV4_ADDRESS_FOR_NG_AMF.*|GNB_IPV4_ADDRESS_FOR_NG_AMF              = "192.168.100.163/24";|
s|GNB_INTERFACE_NAME_FOR_NGU.*|GNB_INTERFACE_NAME_FOR_NGU               = "net2";|
s|GNB_IPV4_ADDRESS_FOR_NGU.*|GNB_IPV4_ADDRESS_FOR_NGU                 = "192.168.100.164/24";|
s|sdr_addrs =.*||
EOF
    cp "$DIR_DEST"/mounted.conf /tmp/mounted.conf
    sed -f "$SED_FILE" < /tmp/mounted.conf > "$DIR_DEST"/mounted.conf

    # add SDR IP ADDRESSES
    if [[ "$rru" == "n300" || "$rru" == "n320" ]] ; then
	perl -i -p0e "s/#clock_src = \"internal\";/#clock_src = \"internal\";\n  sdr_addrs = \"$SDR_ADDRS,clock_source=internal,time_source=internal\";/s" "$DIR_DEST"/mounted.conf
    else
	SED_FILE="/tmp/aw2s_conf.sed"
	cat > "$SED_FILE" <<EOF
s|local_if_name.*|local_if_name  = "$LOC_IF_NAME_AW2S"|
s|remote_address.*|remote_address = "$LOC_ADDR_AW2S"|
s|local_address.*|local_address = "$ADDR_AW2S"|
EOF
	cp "$DIR_DEST"/mounted.conf /tmp/mounted.conf
	sed -f "$SED_FILE" < /tmp/mounted.conf > "$DIR_DEST"/mounted.conf
    fi
    # show changes applied to default conf
    echo "Following changes applied to $CONF_ORIG"
    diff "$DIR_DEST"/mounted.conf "$CONF_ORIG"
    exit 0 # don't know why it returns 1 otherwise...
}

function reconfigure() {
    node_spgwu=$1
    shift
    node_gnb=$1
    shift

    echo "setup: Reconfigure oai5g charts from original ones"
    cd "$HOME"
    rm -rf oai-cn5g-fed
    git clone -b master https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed
    configure $node_spgwu $node_gnb 
}


function start-cn() {
    ns=$1
    shift
    node_spgwu=$1
    shift

    echo "Running start-cn() with namespace: $ns, node_spgwu:$node_spgwu"

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
    ns=$1
    shift
    node_spgwu=$1
    shift
    node_gnb=$1
    shift

    echo "start: run all oai5g pods on namespace: $ns"

    # Check if all FIT nodes are ready
    while :; do
        kubectl wait no --for=condition=Ready $node_gnb && break
        clear
        echo "Wait until gNB FIT node is in READY state"
        kubectl get no
        sleep 5
    done

    start-cn $ns $node_spgwu
    start-gnb $ns $node_gnb

    echo "****************************************************************************"
    echo "When you finish, to clean-up the k8s cluster, please run demo-oai.py --clean"
}

function stop-cn(){
    ns=$1
    shift

    echo "helm -n$ns uninstall oai-spgwu-tiny oai-nrf oai-udr oai-udm oai-ausf oai-smf oai-amf mysql"
    helm -n$ns uninstall mysql
    helm -n$ns uninstall oai-ausf
    helm -n$ns uninstall oai-udm
    helm -n$ns uninstall oai-udr
    helm -n$ns uninstall oai-amf
    helm -n$ns uninstall oai-smf
    helm -n$ns uninstall oai-nrf
}


function stop-gnb(){
    ns=$1
    shift

    echo "helm -n$ns uninstall oai-gnb"
    helm -n$ns uninstall oai-gnb
}


function stop() {
    ns=$1
    shift

    echo "Running stop() on namespace:$ns"

    res=$(helm -n $ns ls | wc -l)
    if test $res -gt 1; then
        echo "Remove all 5G OAI pods"
	stop-cn $ns
	stop-gnb $ns
    else
        echo "OAI5G demo is not running, there is no pod on namespace $ns !"
    fi
    echo "Delete namespace $ns"
    echo "kubectl delete ns $ns"
    kubectl delete ns $ns || true
}


#Handle the different function calls with or without input parameters
if test $# -lt 1; then
    usage
else
    if [ "$1" == "init" ]; then
        if test $# -eq 3; then
            init $2 $3
        elif test $# -eq 1; then
	    init $DEF_NS $DEF_RRU
        else
            usage
        fi
    elif [ "$1" == "start" ]; then
        if test $# -eq 4; then
            start $2 $3 $4
        elif test $# -eq 1; then
	    start $DEF_NS $DEF_NODE_SPGWU $DEF_NODE_GNB
	else
            usage
        fi
    elif [ "$1" == "stop" ]; then
        if test $# -eq 2; then
            stop $2
        elif test $# -eq 1; then
	    stop $DEF_NS
	else
            usage
        fi
    elif [ "$1" == "configure-all" ]; then
        if test $# -eq 3; then
            configure-all $2 $3
	    exit 0
        elif test $# -eq 1; then
	    configure-all $DEF_NODE_SPGWU $DEF_NODE_GNB
	else
            usage
        fi
    elif [ "$1" == "reconfigure" ]; then
        if test $# -eq 3; then
            reconfigure $2 $3
        elif test $# -eq 1; then
	    reconfigure $DEF_NODE_SPGWU $DEF_NODE_GNB
	else
            usage
        fi
    elif [ "$1" == "start-cn" ]; then
        if test $# -eq 3; then
            start-cn $2 $3
        elif test $# -eq 1; then
	    start-cn $DEF_NS $DEF_NODE_SPGWU
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
    else
        usage
    fi
fi
