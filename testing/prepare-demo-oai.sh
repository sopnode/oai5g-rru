#!/bin/bash
#
# This script aims to test the oai5g-rru demo script directly on a sopnode server
# see https://github.com/sopnode/oai5g-rru/tree/develop-r2lab
#

# server used for following OAI5G functions
HOST_AMF_UPF="10.10.3.200" # IP adress of the AMF
HOST_GNB="precision-7530" # name of the Kubernetes node on which the gnb will be deployed

# k8s namespace
NS="open5gs"

# Repo/Branch/TAG for code
REPO_OAI5G_RRU="https://github.com/Ziyad-Mabrouk/oai5g-rru.git"
TAG_OAI5G_RRU="gen-cn2"
REPO_OAI_CN5G_FED="https://github.com/Ziyad-Mabrouk/oai-cn5g-fed"
TAG_OAI_CN5G_FED="gen-cn2"

# CN mode
CN_MODE="advance"
#CN_MODE="basic"

# oai5g-rru running mode 
#RUN_MODE="full"
#RUN_MODE="gnb-upf"
RUN_MODE="gnb-only"

# RAN options
#RRU="jaguar"
#RRU="panther"
RRU="rfsim"
#RRU="b210"
#RRU="n300"
#RRU="n320"
#GNB_MODE="cudu"
#GNB_MODE="cucpup"
GNB_MODE="monolithic"

# DNNs 
DNN0="internet"
DNN1="streaming"

# logs configuration
# logs and pcap are automatically retrieved when running demo-oai.sh stop in /tmp/tmp.root/oai5g-stats.tgz
# you should manually erase /tmp/tmp.root/oai5g-stats directory before running another scenario to prevent retrieving old logs/pcaps
LOGS="false"
PCAP="false"
MONITORING="true"
FLEXRIC="true"
LOCAL_INTERFACE="wlp111s0"
#PCAP="true"

# identity used to git pull
RC_NAME="r2labuser"
RC_PWD="r2labuser-pwd"
RC_MAIL="r2labuser@turletti.com"


DIR="$(pwd)"
COMMAND=$(basename $0)

function git_pull(){

    echo "Step 1: clean up previous oai5g-rru and oai-cn5g-fed.git local directories if any"
    cd $DIR
    rm -rf oai5g-rru oai-cn5g-fed
    echo "$0: Clone oai5g-rru and oai-cn5g-fed.git and configure charts and scripts"
    TAG=${OAI_BRANCH:-$TAG_OAI5G_RRU}
    echo "git clone -b $TAG $REPO_OAI5G_RRU"
    git clone -b $TAG $REPO_OAI5G_RRU
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
    echo "./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $MONITORING $FLEXRIC $LOCAL_INTERFACE $DIR $CN_MODE $GNB_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL"
    ./configure-demo-oai.sh update $NS $HOST_AMF_UPF $HOST_GNB $RRU $RUN_MODE $LOGS $PCAP $MONITORING $FLEXRIC $LOCAL_INTERFACE $DIR $CN_MODE $GNB_MODE $DNN0 $DNN1 $RC_NAME $RC_PWD $RC_MAIL
    echo "Step 2: configure OAI5G charts to match the target scenario"
    echo "run init"
    ./demo-oai.sh init
    echo "./demo-oai.sh configure-all"
    ./demo-oai.sh configure-all
    echo "OAI5G charts are now configured for your scenario, you can use the start.sh script to launch your scenario."
}

function usage() {
    echo "$COMMAND: Invalid option"
    echo "USAGE: $COMMAND [-B OAI_BRANCH] [-R RRU] -a|-p|-c"
    echo "$COMMAND -B: select the oai5g-rru tag or branch to pull, default is develop-r2lab."
    echo "$COMMAND -R: select the RRU to use, default is jaguar."
    echo "$COMMAND -a: git pull the latest code and configure the OAI5G charts for the target scenario."
    echo "$COMMAND -p: git pull the latest code. If necessary, you can manually modify the scripts before running configure."
    echo "$COMMAND -c: configure the OAI5G charts for the target scenario, configure must only be run after a fresh pull, i.e., 2 consecutive configure will fail."
    exit 1
}

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

