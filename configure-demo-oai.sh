#!/bin/bash

function update() {
    ns=$1; shift
    node_spgwu=$1; shift
    node_gnb=$1; shift
    regcred_name=$1; shift
    regcred_password=$1; shift
    regcred_email=$1; shift
    

    echo "Configuring chart $OAI5G_BASIC/values.yaml for R2lab"
    cat > /tmp/demo-oai.sed <<EOF
s|DEF_NS=.*|DEF_NS="${ns}"|
s|DEF_NODE_SPGWU=.*|DEF_NODE_SPGWU="${node_spgwu}"|
s|DEF_NODE_GNB=.*|DEF_NODE_GNB="${node_gnb}"|
s|username=r2labuser|username=${regcred_name}|
s|password=r2labuser-pwd|password=${regcred_password}|
s|email=r2labuser@turletti.com|email=${regcred_email}|
EOF

    cp demo-oai.sh /tmp/demo-oai-orig.sh
    echo "Configuring demo-oai.sh script with possible new R2lab FIT nodes and registry credentials"
    sed -f /tmp/demo-oai.sed < /tmp/demo-oai-orig.sh > /root/demo-oai.sh
    diff /tmp/demo-oai-orig.sh /root/demo-oai.sh
}

if test $# -ne 7; then
    echo "val = $#, command= $@"
    echo "USAGE: configure-demo-oai.sh namespace node_spgwu node_gnb regcred_name regcred_password regcred_email "
    exit 1
else
    shift
    echo "Running update with inputs: $@"
    update "$@"
    exit 0
fi
