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

START_IP=100       # first IP offset
MAX_UES=15         # default number of UEs (static list below)

GNB_ID="0xe020"
FULL_KEY="fec86ba6eb707ed08905757b1bb44b8f"
OPC="C42449363BBAD02B66D16BC975D77CC1"
RFSIM_IMSI="001010000001121"

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

function gen_mysql_database() {
    PREFIX_DEMO=$1

    DB_FILE="$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic.sql"
    mkdir -p "$(dirname $DB_FILE)"
    rm -f "$DB_FILE"

    echo "Generating dynamic MySQL DB → $DB_FILE"

    #
    # STATIC TABLE DEFINITIONS (unaltered from original)
    #
    cat << 'EOF' >> "$DB_FILE"
CREATE TABLE IF NOT EXISTS `AuthenticationSubscription` (
  `ueid` varchar(255) NOT NULL,
  `authenticationMethod` varchar(255) DEFAULT NULL,
  `encPermanentKey` varchar(255) DEFAULT NULL,
  `protectionParameterId` varchar(255) DEFAULT NULL,
  `sequenceNumber` json DEFAULT NULL,
  `authenticationManagementField` varchar(255) DEFAULT NULL,
  `algorithmId` varchar(255) DEFAULT NULL,
  `encOpcKey` varchar(255) DEFAULT NULL,
  `encTopcKey` varchar(255) DEFAULT NULL,
  `vectorGenerationInHss` tinyint(1) DEFAULT NULL,
  `n5gcAuthMethod` varchar(255) DEFAULT NULL,
  `rgAuthenticationInd` tinyint(1) DEFAULT NULL,
  `supi` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ueid`)
);
CREATE TABLE IF NOT EXISTS `AccessAndMobilitySubscriptionData` (
  `ueid` varchar(255) NOT NULL,
  `subscribedUeAmbr` json DEFAULT NULL,
  PRIMARY KEY (`ueid`)
);
CREATE TABLE IF NOT EXISTS `SessionManagementSubscriptionData` (
  `ueid` varchar(255) NOT NULL,
  `singleNssai` json DEFAULT NULL,
  `dnnConfigurations` json DEFAULT NULL,
  PRIMARY KEY (`ueid`)
);
EOF

    #
    # UE INSERTS (dynamic)
    #
    COUNT=0
    IP=$START_IP

    for entry in "${UE_SLICE_MAP[@]}"; do
        (( COUNT == MAX_UES )) && break

        IMSI_SUFFIX="${entry%%:*}"
        SLICE="${entry##*:}"

        IMSI="${MCC}${MNC}${IMSI_SUFFIX}"

        if [[ "$SLICE" == "1" ]]; then
            SLICE_IPV4_PREFIX="$SLICE1_IPV4_PREFIX"
            SST="$SLICE1_SST"
            SD="$SLICE1_SD"
        else
            SLICE_IPV4_PREFIX="$SLICE2_IPV4_PREFIX"
            SST="$SLICE2_SST"
            SD="$SLICE2_SD"
        fi

        IPADDR="${SLICE_IPV4_PREFIX}.${IP}"
        ((IP++))

        # AuthenticationSubscription
        echo "INSERT INTO AuthenticationSubscription VALUES" \
        "('$IMSI','5G_AKA','$FULL_KEY','$FULL_KEY','{\"sqn\":\"000000000020\",\"sqnScheme\":\"NON_TIME_BASED\",\"lastIndexes\":{\"ausf\":0}}'," \
        "'8000','milenage','$OPC',NULL,NULL,NULL,NULL,'$IMSI');" >> "$DB_FILE"

        # AccessAndMobilitySubscriptionData
        echo "INSERT INTO AccessAndMobilitySubscriptionData VALUES" \
        "('$IMSI','{\"uplink\":\"1Gbps\",\"downlink\":\"2Gbps\"}');" >> "$DB_FILE"

        # SessionManagementSubscriptionData
        echo "INSERT INTO SessionManagementSubscriptionData VALUES" \
        "('$IMSI','[{\"sst\":$SST,\"sd\":\"$SD\"}]'," \
        "'{\"${DNN0}\":{\"staticIpAddress\":[{\"ipv4Addr\":\"$IPADDR\"}]}}');" >> "$DB_FILE"

        ((COUNT++))
    done

    echo "✔ MySQL DB generated"
}

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
EOF

    cp "$PREFIX_DEMO"/demo-oai.sh "$TMP"/demo-oai-orig.sh
    sed -f "$TMP"/demo-oai.sed < "$TMP"/demo-oai-orig.sh > "$PREFIX_DEMO"/demo-oai.sh
    diff "$TMP"/demo-oai-orig.sh "$PREFIX_DEMO"/demo-oai.sh

    ### NEW ELEGANT DB GENERATION ###
    gen_mysql_database "$PREFIX_DEMO"
}

if test $# -ne 16; then
    echo "USAGE: configure-demo-oai.sh namespace node_amf_upf node_gnb rru gnb_only logs pcap prefix_demo cn_mode gnb_mode DNN0 DNN1 regcred_name regcred_password regcred_email"
    exit 1
else
    shift
    echo "Running update with inputs: $@"
    update "$@"
    exit 0
fi
