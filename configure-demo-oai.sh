#!/bin/bash

##########################################################################################
#    Configure here the following variables used in demo-oai.sh script
#
MCC="001" # default is "208"
MNC="01" # default is "95"
TAC="1" # default is "1"
SST0="1" # default is "1"
DNN="oai.ipv4" # default is "oai.ipv4"
FULL_KEY="fec86ba6eb707ed08905757b1bb44b8f" # default is "8baf473f2f8fd09487cccbd7097c6862"
OPC="C42449363BBAD02B66D16BC975D77CC1" # default is "8E27B6AF0E692E750F32667A3B14605D"
RFSIM_IMSI="001010000001121" # default is "208950000001121"
##########################################################################################

function update() {
    NS=$1; shift
    NODE_AMF_SPGWU=$1; shift
    NODE_GNB=$1; shift
    RRU=$1; shift 
    GNB_ONLY=$1; shift # boolean in [true, false]
    LOGS=$1; shift # boolean in [true, false]
    PCAP=$1; shift # boolean in [true, false]
    PREFIX_DEMO=$1; shift
    REGCRED_NAME=$1; shift
    REGCRED_PWD=$1; shift
    REGCRED_EMAIL=$1; shift

    # Convert to lowercase boolean parameters
    GNB_ONLY="${GNB_ONLY,,}"
    LOGS="${LOGS,,}"
    PCAP="${PCAP,,}"
    

    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/demo-oai.sed <<EOF
s|@DEF_NS@|$NS|
s|@DEF_NODE_AMF_SPGWU@|$NODE_AMF_SPGWU|
s|@DEF_NODE_GNB@|$NODE_GNB|
s|@DEF_RRU@|$RRU|
s|@DEF_GNB_ONLY@|$GNB_ONLY|
s|@DEF_LOGS@|$LOGS|
s|@DEF_PCAP@|$PCAP|
s|@DEF_MCC@|${MCC}|g
s|@DEF_MNC@|${MNC}|g
s|@DEF_TAC@|${TAC}|g
s|@DEF_SST0@|${SST0}|g
s|@DEF_DNN@|${DNN}|g
s|@DEF_FULL_KEY@|${FULL_KEY}|g
s|@DEF_OPC@|${OPC}|g
s|@DEF_RFSIM_IMSI@|${RFSIM_IMSI}|g
s|@DEF_PREFIX_DEMO@|$PREFIX_DEMO|
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

if test $# -ne 12; then
    echo "USAGE: configure-demo-oai.sh namespace node_amf_spgwu node_gnb rru gnb_only logs pcap prefix_demo regcred_name regcred_password regcred_email "
    exit 1
else
    shift
    echo "Running update with inputs: $@"
    update "$@"
    exit 0
fi
