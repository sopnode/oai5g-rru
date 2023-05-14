#!/bin/bash

DIR="/root/oai5g-tests"
REPO_OAI5G_RRU="https://github.com/sopnode/oai5g-rru.git"
TAG_OAI5G_RRU="rnis"
REPO_OAI_CN5G_FED="https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git"
TAG_OAI_CN5G_FED="r2lab-rrus-rnis"
NS="rnis"
HOST_AMF_SPGWU="sopnode-w1.inria.fr"
HOST_GNB="sopnode-w1.inria.fr"
RRU="rfsim"
GNB_ONLY="False"
PCAP="False"
RC_NAME="r2labuser"
RC_PWD="r2labuser-pwd"
RC_MAIL="r2labuser@turletti.com"

echo "$0: Clean up previous oai5g-rru and oai-cn5g-fed.git local directories if any"
cd $DIR
rm -rf oai5g-rru oai-cn5g-fed
echo "$0: Clone oai5g-rru and oai-cn5g-fed.git and configure charts and scripts"
echo "git clone -b $TAG_OAI5G_RRU $REPO_OAI5G_RRU"
git clone -b $TAG_OAI5G_RRU $REPO_OAI5G_RRU
echo "git clone -b $TAG_OAI_CN5G_FED $REPO_OAI_CN5G_FED"
git clone -b $TAG_OAI_CN5G_FED $REPO_OAI_CN5G_FED
cp oai5g-rru/configure-demo-oai.sh .
cp oai5g-rru/demo-oai.sh .
chmod a+x demo-oai.sh
echo "./configure-demo-oai.sh update $NS $HOST_AMF_SPGWU $HOST_GNB $RRU $GNB_ONLY $PCAP $DIR $RC_NAME $RC_PWD $RC_MAIL"
./configure-demo-oai.sh update $NS $HOST_AMF_SPGWU $HOST_GNB $RRU $GNB_ONLY $PCAP $DIR $RC_NAME $RC_PWD $RC_MAIL
echo "run init"
./demo-oai.sh init $NS
echo "./demo-oai.sh configure-all $HOST_AMF_SPGWU $HOST_GNB $RRU $PCAP"
./demo-oai.sh configure-all $HOST_AMF_SPGWU $HOST_GNB $RRU $PCAP 

