#!/bin/bash

##########################################################################################
#  Configure here the following variables used in demo-oai.sh script and in MYSQL database
#
MCC="001"
MNC="01"
TAC="1"

# DNN0 and DNN1 must be set in demo-oai.py or in prepare-demo-oai.sh scripts
DNN0_PDU_TYPE="IPV4"
DNN1_PDU_TYPE="IPV4"

# Slice 1
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

# Slice 2
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

START_IP=100

GNB_ID="0xe020"
FULL_KEY="fec86ba6eb707ed08905757b1bb44b8f"
OPC="C42449363BBAD02B66D16BC975D77CC1"
RFSIM_IMSI="001010000001121"

##########################################################################################
TMP="/tmp/tmp.$USER"
mkdir -p $TMP

# UE → slice mapping
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

    # sopnode suffix
    [[ $NODE_AMF_UPF == sopnode* ]] && NODE_AMF_UPF="${NODE_AMF_UPF}-v30"
    [[ $NODE_GNB == sopnode* ]] && NODE_GNB="${NODE_GNB}-v30"

    GNB_ONLY="${GNB_ONLY,,}"
    LOGS="${LOGS,,}"
    PCAP="${PCAP,,}"

    [[ "$CN_MODE" = "advance" ]] && mode="advance" && MODE="ADVANCE" || mode="basic" && MODE="BASIC"

    echo "Configuring demo-oai.sh script"
    cat > "$TMP"/demo-oai.sed <<EOF
s|@DEF_NS@|$NS|
s|@DEF_NODE_AMF_UPF@|$NODE_AMF_UPF|
s|@DEF_NODE_GNB@|$NODE_GNB|
s|@DEF_RRU@|$RRU|
s|@DEF_RUN_MODE@|$RUN_MODE|
s|@DEF_GNB_MODE@|$GNB_MODE|
s|@DEF_LOGS@|$LOGS|
s|@DEF_PCAP@|$PCAP|
s|@DEF_MCC@|${MCC}|g
s|@DEF_MNC@|${MNC}|g
s|@DEF_TAC@|${TAC}|g
s|@DEF_DNN0@|${DNN0}|
s|@DEF_DNN0_PDU_TYPE@|${DNN0_PDU_TYPE}|
s|@DEF_DNN1@|${DNN1}|
s|@DEF_DNN1_PDU_TYPE@|${DNN1_PDU_TYPE}|
s|@DEF_SLICE1_SST@|${SLICE1_SST}|
s|@DEF_SLICE1_SD@|${SLICE1_SD}|
s|@DEF_SLICE1_5QI@|${SLICE1_5QI}|
s|@DEF_SLICE1_UPLINK@|${SLICE1_UPLINK}|
s|@DEF_SLICE1_DOWNLINK@|${SLICE1_DOWNLINK}|
s|@DEF_SLICE2_SST@|${SLICE2_SST}|
s|@DEF_SLICE2_SD@|${SLICE2_SD}|
s|@DEF_SLICE2_5QI@|${SLICE2_5QI}|
s|@DEF_SLICE2_UPLINK@|${SLICE2_UPLINK}|
s|@DEF_SLICE2_DOWNLINK@|${SLICE2_DOWNLINK}|
s|@DEF_GNB_ID@|${GNB_ID}|
s|@DEF_FULL_KEY@|${FULL_KEY}|g
s|@DEF_OPC@|${OPC}|g
s|@DEF_RFSIM_IMSI@|${RFSIM_IMSI}|g
s|@DEF_PREFIX_DEMO@|$PREFIX_DEMO|
s|@MODE@|$MODE|g
s|@mode@|$mode|g
s|@DEF_REGCRED_NAME@|$REGCRED_NAME|
s|@DEF_REGCRED_PWD@|$REGCRED_PWD|
s|@DEF_REGCRED_EMAIL@|$REGCRED_EMAIL|
EOF

    cp "$PREFIX_DEMO"/demo-oai.sh "$TMP"/demo-oai-orig.sh
    sed -f "$TMP"/demo-oai.sed < "$TMP"/demo-oai-orig.sh > $PREFIX_DEMO/demo-oai.sh
    diff "$TMP"/demo-oai-orig.sh $PREFIX_DEMO/demo-oai.sh

    ##########################################################################
    # GENERATE MYSQL DATABASE DYNAMICALLY
    ##########################################################################
    ORIG_DB="$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic-orig.sql"
    NEW_DB="$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic.sql"

    echo "Generating dynamic MySQL database: $NEW_DB"
    awk '/INSERT INTO `AuthenticationSubscription`/{exit} {print}' $ORIG_DB > $NEW_DB

    IP=$START_IP

    for entry in "${UE_SLICE_MAP[@]}"; do
        IMSI=$(echo "$entry" | cut -d: -f1)
        SLICE=$(echo "$entry" | cut -d: -f2)
        UEID="${MCC}${MNC}${IMSI}"

        if [[ "$SLICE" == "1" ]]; then
            SST="$SLICE1_SST"; SD="$SLICE1_SD"
            PREFIX="$SLICE1_IPV4_PREFIX"
        else
            SST="$SLICE2_SST"; SD="$SLICE2_SD"
            PREFIX="$SLICE2_IPV4_PREFIX"
        fi

        IPADDR="$PREFIX.$IP"
        IP=$((IP + 1))

        echo "INSERT INTO AuthenticationSubscription VALUES('$UEID','5G_AKA','$FULL_KEY','$FULL_KEY','{\"sqn\":\"000000000020\",\"sqnScheme\":\"NON_TIME_BASED\",\"lastIndexes\":{\"ausf\":0}}','8000','milenage','$OPC',NULL,NULL,NULL,NULL,'$UEID');" >> $NEW_DB

        echo "INSERT INTO SessionManagementSubscriptionData VALUES('$UEID','${MCC}${MNC}','{\"sst\": $SST, \"sd\": \"$SD\"}','{\"${DNN0}\":{\"pduSessionTypes\":{\"defaultSessionType\":\"${DNN0_PDU_TYPE}\"},\"staticIpAddress\":[{\"ipv4Addr\": \"$IPADDR\"}]}}');" >> $NEW_DB
    done

    awk '/ALTER TABLE/{found=1} found {print}' $ORIG_DB >> $NEW_DB
    echo "MySQL generation complete."
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
