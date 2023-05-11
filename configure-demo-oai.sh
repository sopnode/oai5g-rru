#!/bin/bash

####
#    Configure here the following variables used in demo-oai.sh script
#
MCC="208" # default is "208"
MNC="95" # default is "95"
TAC="1" # default is "1"
SST="1" # default is "1"
#DNN="oai.ipv4" # default is "oai.ipv4"
DNN="oai" # default is "oai.ipv4"
FULL_KEY="8baf473f2f8fd09487cccbd7097c6862" # default is "8baf473f2f8fd09487cccbd7097c6862"
OPC="8E27B6AF0E692E750F32667A3B14605D" # default is "8E27B6AF0E692E750F32667A3B14605D"
RFSIM_IMSI="208950000001121" # default is "208950000001121"
####

function update() {
    ns=$1; shift
    node_amf_spgwu=$1; shift
    node_gnb=$1; shift
    rru=$1; shift
    gnb_only=$1; shift
    pcap=$1; shift
    regcred_name=$1; shift
    regcred_password=$1; shift
    regcred_email=$1; shift
    

    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/demo-oai.sed <<EOF
s|DEF_NS=.*|DEF_NS="${ns}"|
s|DEF_NODE_AMF_SPGWU=.*|DEF_NODE_AMF_SPGWU="${node_amf_spgwu}"|
s|DEF_NODE_GNB=.*|DEF_NODE_GNB="${node_gnb}"|
s|DEF_RRU=.*|DEF_RRU="${rru}"|
s|DEF_GNB_ONLY=.*|DEF_GNB_ONLY="${gnb_only}"|
s|DEF_PCAP=.*|DEF_PCAP="${pcap}"|
s|username=r2labuser|username=${regcred_name}|
s|password=r2labuser-pwd|password=${regcred_password}|
s|email=r2labuser@turletti.com|email=${regcred_email}|
s|@DEF_MCC@|${MCC}|g
s|@DEF_MNC@|${MNC}|g
s|@DEF_TAC@|${TAC}|g
s|@DEF_SST@|${SST}|g
s|@DEF_DNN@|${DNN}|g
s|@DEF_FULL_KEY@|${FULL_KEY}|g
s|@DEF_OPC@|${OPC}|g
s|@DEF_RFSIM_IMSI@|${RFSIM_IMSI}|g
EOF

    cp demo-oai.sh /tmp/demo-oai-orig.sh
    echo "Configuring demo-oai.sh script with possible new R2lab FIT nodes and registry credentials"
    sed -f /tmp/demo-oai.sed < /tmp/demo-oai-orig.sh > /root/demo-oai.sh
    diff /tmp/demo-oai-orig.sh /root/demo-oai.sh
}

if test $# -ne 10; then
    echo "USAGE: configure-demo-oai.sh namespace node_amf_spgwu node_gnb rru gnb_only pcap regcred_name regcred_password regcred_email "
    exit 1
else
    shift
    echo "Running update with inputs: $@"
    update "$@"
    exit 0
fi
