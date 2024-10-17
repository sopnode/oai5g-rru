#!/bin/bash

##########################################################################################
#  Configure here the following variables used in demo-oai.sh script and in MYSQL database
#
MCC="001" 
MNC="01" 
TAC="1" 

# DNN0 and DNN1 must be set in demo-oai.py or in prepare-demo-oai.sh scripts to configure Quectel UE
#  if DNN1=="none", configure a single DNN will be configured in the mysql database
DNN0_PDU_TYPE="IPV4" # "IPV4" or "IPV4V6"
DNN1_PDU_TYPE="IPV4" # "IPV4" or "IPV4V6"

# NSSAI (SST,SD) Configuration
#
# NOTA on SD format encoding in the charts
# - in mysql database, SD field is a string/hexadecimal without 0x prefix,
#    and encoded with the format: \"ABCDEF\"
# - in gNB configmaps sd format should include 0x prexix or use the decimal form
# - in core/config.yaml and ue/values.yaml, it is in hex form without 0x prefix
SLICE1_SST="1"
SLICE1_SD="000002"
SLICE1_5QI="5" # non-GBR
SLICE1_ARP_PRIORITY_LEVEL="15"
SLICE1_ARP_PREEMPT_CAP="NOT_PREEMPT" # "NOT_PREEMPT" or "MAY_PREEMPT" # to trigger preemption
SLICE1_ARP_PREEMPT_VULN="PREEMPTABLE" # "PREEMPTABLE" or "NOT_PREEMPT" # preemption vulnerability
SLICE1_PRIORITY_LEVEL="1"
SLICE1_UPLINK="20Mbps"
SLICE1_DOWNLINK="40Mbps"

SLICE2_SST="2"
SLICE2_SD="000002"
SLICE2_5QI="6" # non-GBR
SLICE2_ARP_PRIORITY_LEVEL="15"
SLICE2_ARP_PREEMPT_CAP="NOT_PREEMPT" # "NOT_PREEMPT" or "MAY_PREEMPT" # to trigger preemption
SLICE2_ARP_PREEMPT_VULN="PREEMPTABLE" # "PREEMPTABLE" or "NOT_PREEMPT" # preemption vulnerability
SLICE2_PRIORITY_LEVEL="1"
SLICE2_UPLINK="100Mbps"
SLICE2_DOWNLINK="200Mbps"

GNB_ID="0xe020"
FULL_KEY="fec86ba6eb707ed08905757b1bb44b8f" # default is "8baf473f2f8fd09487cccbd7097c6862"
OPC="C42449363BBAD02B66D16BC975D77CC1" # default is "8E27B6AF0E692E750F32667A3B14605D"
RFSIM_IMSI="001010000001121"

##########################################################################################

function update() {
    NS=$1; shift
    NODE_AMF_UPF=$1"-v100"; shift
    NODE_GNB=$1"-v100"; shift
    RRU=$1; shift 
    RUN_MODE=$1; shift # in ["full", "gnb-only", "gnb-upf"]
    LOGS=$1; shift # boolean in [true, false]
    PCAP=$1; shift # boolean in [true, false]
    PREFIX_DEMO=$1; shift
    CN_MODE=$1; shift
    GNB_MODE=$1; shift
    DNN0=$1; shift
    DNN1=$1; shift
    REGCRED_NAME=$1; shift
    REGCRED_PWD=$1; shift
    REGCRED_EMAIL=$1; shift

    # Convert to lowercase boolean parameters
    GNB_ONLY="${GNB_ONLY,,}"
    LOGS="${LOGS,,}"
    PCAP="${PCAP,,}"

    if [[ "$CN_MODE" = "advance" ]]; then
	mode="advance"
	MODE="ADVANCE"
    else
	mode="basic"
	MODE="BASIC"
    fi
    
    echo "Configuring demo-oai.sh script"
    cat > /tmp/demo-oai.sed <<EOF
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
s|@DEF_SLICE1_ARP_PRIORITY_LEVEL@|${SLICE1_ARP_PRIORITY_LEVEL}|
s|@DEF_SLICE1_ARP_PREEMPT_CAP@|${SLICE1_ARP_PREEMPT_CAP}|
s|@DEF_SLICE1_ARP_PREEMPT_VULN@|${SLICE1_ARP_PREEMPT_VULN}|
s|@DEF_SLICE1_PRIORITY_LEVEL@|${SLICE1_PRIORITY_LEVEL}|
s|@DEF_SLICE1_UPLINK@|${SLICE1_UPLINK}|
s|@DEF_SLICE1_DOWNLINK@|${SLICE1_DOWNLINK}|
s|@DEF_SLICE2_SST@|${SLICE2_SST}|
s|@DEF_SLICE2_SD@|${SLICE2_SD}|
s|@DEF_SLICE2_5QI@|${SLICE2_5QI}|
s|@DEF_SLICE2_ARP_PRIORITY_LEVEL@|${SLICE2_ARP_PRIORITY_LEVEL}|
s|@DEF_SLICE2_ARP_PREEMPT_CAP@|${SLICE2_ARP_PREEMPT_CAP}|
s|@DEF_SLICE2_ARP_PREEMPT_VULN@|${SLICE2_ARP_PREEMPT_VULN}|
s|@DEF_SLICE2_PRIORITY_LEVEL@|${SLICE2_PRIORITY_LEVEL}|
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

    cp "$PREFIX_DEMO"/demo-oai.sh /tmp/demo-oai-orig.sh
    echo "Configuring demo-oai.sh script with possible new R2lab FIT nodes and registry credentials"
    sed -f /tmp/demo-oai.sed < /tmp/demo-oai-orig.sh > $PREFIX_DEMO/demo-oai.sh
    diff /tmp/demo-oai-orig.sh $PREFIX_DEMO/demo-oai.sh

    DIR_GENERIC_DB="$PREFIX_DEMO/oai5g-rru/patch-mysql"
    if [[ "$DNN1" = "none" ]]; then
	echo "Patching oai_db-basic.sql generic database for R2lab UEs with DNN0 only"
	oai_db_basic_template="oai_db-basic-generic.sql"
    else
	echo "Patching oai_db-basic.sql generic database for R2lab UEs with both DNN0 and DNN1"
	oai_db_basic_template="oai_db-basic-generic-2dnn.sql"
    fi
    cp $DIR_GENERIC_DB/${oai_db_basic_template} /tmp/${oai_db_basic_template}
    sed -f /tmp/demo-oai.sed < /tmp/${oai_db_basic_template} > $DIR_GENERIC_DB/oai_db-basic.sql
    diff $DIR_GENERIC_DB/${oai_db_basic_template} $DIR_GENERIC_DB/oai_db-basic.sql

}

if test $# -ne 16; then
    echo "USAGE: configure-demo-oai.sh namespace node_amf_upf node_gnb rru gnb_only logs pcap prefix_demo cn_mode gnb_mode DNN0 DNN1 regcred_name regcred_password regcred_email "
    exit 1
else
    shift
    echo "Running update with inputs: $@"
    update "$@"
    exit 0
fi
