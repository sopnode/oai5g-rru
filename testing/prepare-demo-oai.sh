#!/bin/bash
#
# This script aims to test the oai5g-rru demo script directly on a sopnode server
# see https://github.com/sopnode/oai5g-rru/tree/develop-r2lab
#

# server used for following OAI5G functions
HOST_AMF_UPF="sopnode-w1"
HOST_GNB="sopnode-w1"

# k8s namespace
NS="oaiw1"

# Repo/Branch/TAG for code
REPO_OAI5G_RRU="https://github.com/sopnode/oai5g-rru.git"
#TAG_OAI5G_RRU="2024.w31"
TAG_OAI5G_RRU="develop-r2lab-2dnn"
REPO_OAI_CN5G_FED="https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git"
#TAG_OAI_CN5G_FED="develop-r2lab"
TAG_OAI_CN5G_FED="develop-r2lab-2dnn"

# CN mode
CN_MODE="advance"
#CN_MODE="basic"

# oai5g-rru running mode 
RUN_MODE="full"
#RUN_MODE="gnb-upf"
#RUN_MODE="gnb-only"

# RAN options
RRU="jaguar"
#HOST_GNB="fit02"
#HOST_GNB="up02"
#RRU="rfsim"
#RRU="b210"
#RRU="n320"
GNB_MODE="cudu"
#GNB_MODE="cucpup"
#GNB_MODE="monolithic"

# DNNs 
DNN0="oai"
DNN1="internet"
#DNN1="none"

# logs configuration
LOGS="true"
PCAP="false"
#PCAP="true"

# identity used to git pull
RC_NAME="r2labuser"
RC_PWD="r2labuser-pwd"
RC_MAIL="r2labuser@turletti.com"


DIR="$(pwd)"
COMMAND=$(basename $0)

function usage() {
    echo "USAGE:"
    echo "$COMMAND all: git pull the latest code and configure the OAI5G charts for the target scenario"
    echo "$COMMAND pull: git pull the latest code. If necessary, you can manually modify the scripts before running configure."
    echo "$COMMAND configure: configure the OAI5G charts for the target scenario, configure must only be run after a fresh pull, i.e., 2 consecutive configure will fail."
    exit 1
}

function git_pull(){

    echo "Step 1: clean up previous oai5g-rru and oai-cn5g-fed.git local directories if any"
    cd $DIR
    rm -rf oai5g-rru oai-cn5g-fed
    echo "$0: Clone oai5g-rru and oai-cn5g-fed.git and configure charts and scripts"
    echo "git clone -b $TAG_OAI5G_RRU $REPO_OAI5G_RRU"
    git clone -b $TAG_OAI5G_RRU $REPO_OAI5G_RRU
    echo "git clone -b $TAG_OAI_CN5G_FED $REPO_OAI_CN5G_FED"
    git clone -b $TAG_OAI_CN5G_FED $REPO_OAI_CN5G_FED
    echo "Step 2: retrieve latest configure-demo-oai.sh and demo-oai.sh scripts"
    cp oai5g-rru/configure-demo-oai.sh .
    cp oai5g-rru/demo-oai.sh .
    chmod a+x demo-oai.sh
    echo "Pull done. If necessary, you can manually modify these 2 scripts before running $COMMAND configure."
}


function configure_all_scripts(){
    echo "Step 1: use parameters from configure-demo-oai.sh to configure demo-oai.sh script"
    echo "./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $DIR $CN_MODE $GNB_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL"
    ./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $DIR $CN_MODE $GNB_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL
    echo "Step 2: configure OAI5G charts to match the target scenario"
    echo "run init"
    ./demo-oai.sh init
    echo "./demo-oai.sh configure-all"
    ./demo-oai.sh configure-all
    echo "OAI5G charts are now configured for your scenario, you can use the start.sh script to launch your scenario."
}

if test $# -ne 1
        then usage
fi
if [[ $1 = 'all' ]]; then
    git_pull
    configure_all_scripts
elif [[ $1 = 'pull' ]]; then
    git_pull
elif [[ $1 = 'configure' ]]; then
    configure_all_scripts
else
    usage
fi

