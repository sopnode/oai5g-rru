#!/bin/bash
#
# Usage: prepare-demo-oai.sh [TAG_OAI5G_RRU]
#
# This script aims to test oai5g-rru demo script without fit nodes,
# by running all the pods on sopnode servers and simulating RAN with rfsim
#

#!/bin/bash

DIR="/home/github-runner/actions-runner/_work/test-oai5g-rru"
#DIR="/root/test-oai5g-rru"
REPO_OAI5G_RRU="https://github.com/sopnode/oai5g-rru.git"
#TAG_OAI5G_RRU="v2.0.1-1.0-1.0"
#TAG_OAI5G_RRU="master"
if [ $# -eq 1 ]
then
    TAG_OAI5G_RRU="$1"
else
    #TAG_OAI5G_RRU="develop-r2lab"
    TAG_OAI5G_RRU="v2.0.1-1.0-1.0"
fi
echo "***** Testing demo oai5g-rru, TAG: $1"
REPO_OAI_CN5G_FED="https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git"
#TAG_OAI_CN5G_FED="develop-r2lab"
TAG_OAI_CN5G_FED="v2.0.1-1.0"
NS="oaiw1-ci"
HOST_AMF_UPF="sopnode-w1"
HOST_GNB="sopnode-w1"
#HOST_GNB="fit02"
#HOST_GNB="up02"
#RRU="rfsim"
#RRU="b210"
RRU="jaguar"
#RRU="n300"
RUN_MODE="full"
#RUN_MODE="gnb-only"
#CN_MODE="advance"
CN_MODE="basic"
GNB_MODE="monolithic"
#GNB_MODE="cudu"
#GNB_MODE="cucpup"
DNN0="oai"
DNN1="none"
LOGS="true"
PCAP="false"
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
echo "./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $DIR $CN_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL"
./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $DIR $CN_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL
echo "run init"
./demo-oai.sh init
echo "./demo-oai.sh configure-all"
./demo-oai.sh configure-all
