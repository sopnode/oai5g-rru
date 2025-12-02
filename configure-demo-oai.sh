#!/bin/bash

##########################################################################################
#  Configure here the following variables used in demo-oai.sh script and in MYSQL database
#
MCC="001"
MNC="01"
TAC="1"

DNN0_PDU_TYPE="IPV4"
DNN1_PDU_TYPE="IPV4"

SLICE1_SST="1"
SLICE1_SD="EMPTY"
SLICE1_5QI="9"
SLICE1_ARP_PRIORITY_LEVEL="8"
SLICE1_ARP_PREEMPT_CAP="NOT_PREEMPT"
SLICE1_ARP_PREEMPT_VULN="PREEMPTABLE"
SLICE1_PRIORITY_LEVEL="1"
SLICE1_UPLINK="20Mbps"
SLICE1_DOWNLINK="40Mbps"
SLICE1_IPV4_PREFIX="12.1.1"

SLICE2_SST="1"
SLICE2_SD="000001"
SLICE2_5QI="5"
SLICE2_ARP_PRIORITY_LEVEL="1"
SLICE2_ARP_PREEMPT_CAP="NOT_PREEMPT"
SLICE2_ARP_PREEMPT_VULN="PREEMPTABLE"
SLICE2_PRIORITY_LEVEL="1"
SLICE2_UPLINK="100Mbps"
SLICE2_DOWNLINK="200Mbps"
SLICE2_IPV4_PREFIX="14.1.1"

START_IP=11

GNB_ID="0xe020"
FULL_KEY="fec86ba6eb707ed08905757b1bb44b8f"
OPC="C42449363BBAD02B66D16BC975D77CC1"
RFSIM_IMSI="001010000001121"

##########################################################################################
# UE → Slice mapping (modifiable by user)
UE_SLICE_MAP=(
  "0000000001:1"
  "0000000002:1"
  "0000000003:1"
  "0000000004:1"
  "0000000005:1"
  "0000000006:1"
  "0000000007:2"
  "0000000008:1"
  "0000000009:1"
  "0000000010:1"
  "0000000011:1"
  "0000000012:1"
  "0000000013:1"
  "0000000014:1"
  "${RFSIM_IMSI:9}:1"
)

##########################################################################################
TMP="/tmp/tmp.$USER"
mkdir -p $TMP

function gen_dynamic_mysql() {
    PREFIX_DEMO=$1

    SQL_FILE="$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic.sql"
    mkdir -p "$(dirname "$SQL_FILE")"
    echo "Generating dynamic MySQL DB → $SQL_FILE"

cat > "$SQL_FILE" <<EOF
-- AUTO GENERATED OAI DB
START TRANSACTION;

EOF

    COUNTER=$START_IP

    for entry in "${UE_SLICE_MAP[@]}"; do
        UE_ID=${entry%%:*}
        SLICE=${entry#*:}

        IMSI="${MCC}${MNC}${UE_ID}"
        SUPI="${IMSI}"

        if [[ "$SLICE" == "1" ]]; then
            IP="${SLICE1_IPV4_PREFIX}.${COUNTER}"
            sst=$SLICE1_SST
            sd=$SLICE1_SD
            upl=$SLICE1_UPLINK
            dwn=$SLICE1_DOWNLINK
            qfi=$SLICE1_5QI
            arp=$SLICE1_ARP_PRIORITY_LEVEL
        else
            IP="${SLICE2_IPV4_PREFIX}.${COUNTER}"
            sst=$SLICE2_SST
            sd=$SLICE2_SD
            upl=$SLICE2_UPLINK
            dwn=$SLICE2_DOWNLINK
            qfi=$SLICE2_5QI
            arp=$SLICE2_ARP_PRIORITY_LEVEL
        fi

        # AuthenticationSubscription
cat >> "$SQL_FILE" <<EOF
INSERT INTO AuthenticationSubscription (ueid,authenticationMethod,encPermanentKey,protectionParameterId,sequenceNumber,authenticationManagementField,algorithmId,encOpcKey,encTopcKey,vectorGenerationInHss,n5gcAuthMethod,rgAuthenticationInd,supi)
VALUES ('$IMSI','5G_AKA','$FULL_KEY','$FULL_KEY','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}', '8000','milenage','$OPC',NULL,NULL,NULL,NULL,'$SUPI');
EOF

        # SessionManagementSubscriptionData
cat >> "$SQL_FILE" <<EOF
INSERT INTO SessionManagementSubscriptionData (ueid,servingPlmnid,singleNssai,dnnConfigurations)
VALUES ('$IMSI','${MCC}${MNC}','{"sst": $sst, "sd": "$sd"}','{"internet":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi": $qfi,"arp":{"priorityLevel": $arp,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"$upl","downlink":"$dwn"},"staticIpAddress":[{"ipv4Addr":"$IP"}]}}');
EOF

        COUNTER=$((COUNTER+1))
    done

echo "COMMIT;" >> "$SQL_FILE"
}

##########################################################################################

function update() {
    NS=$1; shift
    NODE_AMF_UPF=$1; shift
    NODE_GNB=$1; shift
    RRU=$1; shift
    RUN_MODE=$1; shift
    LOGS=$1; shift
    PCAP=$1; shift
    PREFIX_DEMO=$1; shift
    CN_MODE=$1; shift
    GNB_MODE=$1; shift
    DNN0=$1; shift
    DNN1=$1; shift
    REGCRED_NAME=$1; shift
    REGCRED_PWD=$1; shift
    REGCRED_EMAIL=$1; shift

    cp "$PREFIX_DEMO"/demo-oai.sh "$TMP"/demo-oai-orig.sh
    sed -f "$TMP"/demo-oai.sed < "$TMP"/demo-oai-orig.sh > $PREFIX_DEMO/demo-oai.sh

    gen_dynamic_mysql "$PREFIX_DEMO"
}

##########################################################################################

if test $# -ne 16; then
    echo "USAGE: configure-demo-oai.sh namespace node_amf_upf node_gnb rru gnb_only logs pcap prefix_demo cn_mode gnb_mode DNN0 DNN1 regcred_name regcred_password regcred_email"
    exit 1
else
    shift
    update "$@"
    exit 0
fi
