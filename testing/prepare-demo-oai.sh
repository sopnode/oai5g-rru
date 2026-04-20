#!/bin/bash
#
# This script aims to deploy the oai5g-rru demo script directly on a sopnode server
# see https://github.com/sopnode/oai5g-rru/tree/develop-r2lab
#

# Server name where AMF/UPF are deployed
#  -- or external AMF IP address when using RUN_MODE="gnb-only"
#  -- in case of external open5gs core, set it to the AMF address:
#     e.g., "10.10.3.200" for open5gs and "10.100.50.234" for free5gc
#
HOST_AMF_UPF="sopnode-w1" 

# Server name where RAN pods are deployed
HOST_GNB="sopnode-w1"

# k8s namespace
NS="oai-ci"

# Repo/tag for oai5g-rru scripts
REPO_OAI5G_RRU="https://github.com/sopnode/oai5g-rru.git"
TAG_OAI5G_RRU="main"

# Repo/tag for OAI charts
REPO_OAI_CN5G_FED="https://gitlab.eurecom.fr/turletti/charts.git"
TAG_OAI_CN5G_FED="main"

# CORE node mode in ["basic", "advance"]
CN_MODE="basic"
#CN_MODE="advance"

# run mode in ["full", "gnb-upf", "gnb-only"]
RUN_MODE="full"
#RUN_MODE="gnb-upf"
#RUN_MODE="gnb-only"

# RRU device in ["benetel1", "benetel2", "jaguar", "panther", "n300", "n320", "b210", "rfsim"]
#RRU="benetel1"
#RRU="benetel2"
#RRU="jaguar"
#RRU="panther"
RRU="rfsim"
#RRU="b210"
#RRU="n300"
#RRU="n320"

# Type of RAN deployment in ["monolithic", "cudu", "cucpup"]
#GNB_MODE="cudu"
#GNB_MODE="cucpup"
GNB_MODE="monolithic"

# DNNs 
DNN0="internet"
DNN1="streaming"

# logs configuration
#   -- logs and pcap are automatically retrieved when running demo-oai.sh stop
#      in /tmp/tmp.root/oai5g-stats.tgz
LOGS="false"
PCAP="false"
MONITORING="false"
FLEXRIC="false"

# Network interface name by multus to deploy CORE pods
LOCAL_CORE_INTERFACE="net-30" # e.g., n3br for ovs

# Network interface name by multus to deploy RAN pods
LOCAL_RAN_INTERFACE="net-30" # e.g., n3br for ovs

# github identity used to git pull
RC_NAME="r2labuser"
RC_PWD="r2labuser-pwd"
RC_MAIL="r2labuser@turletti.com"

# TYPE of NAD used for N2 and N3 interfaces.
# By default, do not export it if macvlan is used. Only useful to change N2/N3 NAD to ovs type.
#export NAD_TYPE_N2N3="ovs" # if not exported, default value is "macvlan"


DIR="$(pwd)"
COMMAND=$(basename "$0")

git_pull(){

    echo "Step 1: clean up previous oai5g-rru and oai-cn5g-fed.git local directories if any"
    cd "$DIR" || exit
    rm -rf oai5g-rru charts
    echo "$0: Clone oai5g-rru and oai-cn5g-fed.git and configure charts and scripts"
    TAG=${OAI_BRANCH:-$TAG_OAI5G_RRU}
    echo "git clone -b $TAG $REPO_OAI5G_RRU"
    git clone -b "$TAG" "$REPO_OAI5G_RRU"
    echo "git clone -b $TAG_OAI_CN5G_FED $REPO_OAI_CN5G_FED"
    git clone -b $TAG_OAI_CN5G_FED $REPO_OAI_CN5G_FED
    echo "Step 2: retrieve latest configure-demo-oai.sh and demo-oai.sh scripts"
    cp oai5g-rru/configure-demo-oai.sh .
    cp oai5g-rru/demo-oai.sh .
    chmod a+x demo-oai.sh
    echo "Pull done. If necessary, you can manually modify these 2 scripts before running $COMMAND configure."
}


configure_all_scripts(){
    echo "Step 1: use parameters from configure-demo-oai.sh to configure demo-oai.sh script"
    echo "./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $MONITORING $FLEXRIC $LOCAL_CORE_INTERFACE $LOCAL_RAN_INTERFACE $DIR $CN_MODE $GNB_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL"
    ./configure-demo-oai.sh update "$NS" "$HOST_AMF_UPF" "$HOST_GNB" "$RRU" "$RUN_MODE" "$LOGS" "$PCAP" "$MONITORING" "$FLEXRIC" "$LOCAL_CORE_INTERFACE" "$LOCAL_RAN_INTERFACE" "$DIR" "$CN_MODE" "$GNB_MODE" "$DNN0" "$DNN1" "$RC_NAME" "$RC_PWD" "$RC_MAIL"
    echo "Step 2: configure OAI5G charts to match the target scenario"
    echo "./demo-oai.sh configure-all"
    ./demo-oai.sh configure-all
    echo "OAI5G charts are now configured for your scenario, you can use the start.sh script to launch your scenario."
}

usage() {
    echo "$COMMAND: Invalid option"
    echo "USAGE: $COMMAND [-B OAI_BRANCH] [-R RRU] -a|-p|-c"
    echo "$COMMAND -B: select the oai5g-rru tag or branch to pull, default is develop-r2lab."
    echo "$COMMAND -R: select the RRU to use, default is jaguar."
    echo "$COMMAND -a: git pull the latest code and configure the OAI5G charts for the target scenario."
    echo "$COMMAND -p: git pull the latest code. If necessary, you can manually modify the scripts before running configure."
    echo "$COMMAND -c: configure the OAI5G charts for the target scenario, configure must only be run after a fresh pull, i.e., 2 consecutive configure will fail."
    exit 1
}

# main starts here

while getopts "apcB:R:" opt; do
  case "$opt" in
    a) action='all'
      ;;
    p) action='pull'
      ;;
    c) action='configure'
      ;;
    B) OAI_BRANCH=$OPTARG
      ;;
    R) RRU_OPT=$OPTARG
      ;;
    *) usage
      ;;
  esac
done

if [ -z "${RRU_OPT}" ]; then
    echo "OAI5G scenario will use default $RRU RRU"
else
    RRU="$RRU_OPT"
    echo "OAI5G scenario will use $RRU RRU"
fi

if [[ "$action" = 'all' ]]; then
    git_pull
    configure_all_scripts
elif [[ "$action" = 'pull' ]]; then
    git_pull
elif [[ "$action" = 'configure' ]]; then
    configure_all_scripts
else
     usage
fi

