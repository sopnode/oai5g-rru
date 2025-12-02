#!/bin/bash

# ------------------------------------------------------------------------------
# Original environnement variables and sed system preserved
# ------------------------------------------------------------------------------

PREFIX_DEMO="$(cd "$(dirname "$0")" && pwd)"
TMP="$PREFIX_DEMO/tmp"
mkdir -p "$TMP"

# Default values (can be overridden externally)
DEF_MCC="${DEF_MCC:-001}"
DEF_MNC="${DEF_MNC:-01}"
DEF_FULL_KEY="${DEF_FULL_KEY:-fec86ba6eb707ed08905757b1bb44b8f}"
DEF_OPC="${DEF_OPC:-C42449363BBAD02B66D16BC975D77CC1}"
START_IP="${START_IP:-11}"
RFSIM_IMSI="${RFSIM_IMSI:-001010000001121}"

# ---------------------------------------------------------------------------
# Elegant dynamic mapping for UEs → slice index (unchanged format)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# update() : original logic preserved
# ---------------------------------------------------------------------------
update() {
    echo "Updating demo-oai.sh with environment parameters"
    cp "$PREFIX_DEMO"/demo-oai.sh "$TMP"/demo-oai-orig.sh
    sed -f "$TMP"/demo-oai.sed < "$TMP"/demo-oai-orig.sh > "$PREFIX_DEMO"/demo-oai.sh
    diff "$TMP"/demo-oai-orig.sh "$PREFIX_DEMO"/demo-oai.sh || true
}

# ---------------------------------------------------------------------------
# NEW: Elegant SQL generation (no mysql CLI)
# ---------------------------------------------------------------------------
generate_dynamic_sql() {

    DB="$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic.sql"
    echo "Generating database at $DB"

    # 1) Copy static top of file (tables definitions unchanged)
    sed '/-- Dynamic IPADDRESS Allocation/,$d' \
        "$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic-template-head.sql" > "$DB"

    echo "-- Dynamic IPADDRESS Allocation" >> "$DB"

    IP=$START_IP

    for entry in "${UE_SLICE_MAP[@]}"; do
        UE=${entry%%:*}
        SLICE=${entry##*:}
        IMSI="${DEF_MCC}${DEF_MNC}${UE}"

        # Slice prefix selection
        if [[ "$SLICE" == "1" ]]; then
            PREFIX="12.1.1"
            SD="FFFFFF"
            QOS_5QI=9
            ARP=8
        else
            PREFIX="14.1.1"
            SD="000001"
            QOS_5QI=5
            ARP=1
        fi

        IPADDR="${PREFIX}.${IP}"
        ((IP++))

        # AuthenticationSubscription
        cat >> "$DB" <<EOF
INSERT INTO \`AuthenticationSubscription\` (\`ueid\`, \`authenticationMethod\`, \`encPermanentKey\`, \`protectionParameterId\`, \`sequenceNumber\`, \`authenticationManagementField\`, \`algorithmId\`, \`encOpcKey\`, \`encTopcKey\`, \`vectorGenerationInHss\`, \`n5gcAuthMethod\`, \`rgAuthenticationInd\`, \`supi\`) VALUES
('${IMSI}', '5G_AKA', '${DEF_FULL_KEY}', '${DEF_FULL_KEY}', '{\"sqn\": \"000000000020\", \"sqnScheme\": \"NON_TIME_BASED\", \"lastIndexes\": {\"ausf\": 0}}', '8000', 'milenage', '${DEF_OPC}', NULL, NULL, NULL, NULL, '${IMSI}');
EOF

        # SessionManagementSubscriptionData
        cat >> "$DB" <<EOF
INSERT INTO \`SessionManagementSubscriptionData\` (\`ueid\`, \`servingPlmnid\`, \`singleNssai\`, \`dnnConfigurations\`) VALUES
('${IMSI}', '${DEF_MCC}${DEF_MNC}', '{\"sst\": 1, \"sd\": \"${SD}\"}','{\"internet\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": ${QOS_5QI},\"arp\":{\"priorityLevel\": ${ARP},\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"20Mbps\", \"downlink\":\"40Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"${IPADDR}\"}]}}');
EOF
    done

    # tail of DB (indexes, commit)
    cat "$PREFIX_DEMO/oai5g-rru/patch-mysql/oai_db-basic-template-tail.sql" >> "$DB"
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------

update
generate_dynamic_sql

echo "Generation complete."
