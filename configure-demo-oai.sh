#!/bin/bash

##########################################################################################
#    Configure here the following variables used in demo-oai.sh script
#
MCC="001" # default is "208"
MNC="01" # default is "95"
TAC="1" # default is "1"
#DNN0 and DNN1 must be set in demo-oai.py or prepare-demo-oai.sh to configure Quectel UE
SLICE1_SST="1"
SLICE1_SD="000002"
SLICE1_5QI="5"
SLICE1_UPLINK="200Mbps"
SLICE1_DOWNLINK="400Mbps"
SLICE2_SST="1"
SLICE2_SD="FFFFFF"
SLICE2_5QI="2"
SLICE2_UPLINK="100Mbps"
SLICE2_DOWNLINK="200Mbps"
GNB_ID="0xe020"
FULL_KEY="fec86ba6eb707ed08905757b1bb44b8f" # default is "8baf473f2f8fd09487cccbd7097c6862"
OPC="C42449363BBAD02B66D16BC975D77CC1" # default is "8E27B6AF0E692E750F32667A3B14605D"
RFSIM_IMSI="001010000001121" # default is "208950000001121"
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
s|@DEF_LOGS@|$LOGS|
s|@DEF_PCAP@|$PCAP|
s|@DEF_MCC@|${MCC}|g
s|@DEF_MNC@|${MNC}|g
s|@DEF_TAC@|${TAC}|g
s|@DEF_DNN0@|${DNN0}|
s|@DEF_DNN1@|${DNN1}|
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

    cp "$PREFIX_DEMO"/demo-oai.sh /tmp/demo-oai-orig.sh
    echo "Configuring demo-oai.sh script with possible new R2lab FIT nodes and registry credentials"
    sed -f /tmp/demo-oai.sed < /tmp/demo-oai-orig.sh > $PREFIX_DEMO/demo-oai.sh
    diff /tmp/demo-oai-orig.sh $PREFIX_DEMO/demo-oai.sh

    DIR_GENERIC_DB="$PREFIX_DEMO/oai5g-rru/patch-mysql"
    cp $DIR_GENERIC_DB/oai_db-basic-generic.sql /tmp/
    echo "Patching oai_db-basic.sql generic database with input parameters"
    sed -f /tmp/demo-oai.sed < /tmp/oai_db-basic-generic.sql > $DIR_GENERIC_DB/oai_db-basic.sql
    diff $DIR_GENERIC_DB/oai_db-basic-generic.sql $DIR_GENERIC_DB/oai_db-basic.sql

}

if test $# -ne 15; then
    echo "USAGE: configure-demo-oai.sh namespace node_amf_upf node_gnb rru gnb_only logs pcap prefix_demo cn_mode DNN0 DNN1 regcred_name regcred_password regcred_email "
    exit 1
else
    shift
    echo "Running update with inputs: $@"
    update "$@"
    exit 0
fi
