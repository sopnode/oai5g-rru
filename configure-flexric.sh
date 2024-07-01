#!/bin/bash 

echo "$0: Configure near_ric (flexric)"
echo "This script must be run with admin privileges"

DIR_RAN_CHARTS=/root/test-oai.e2/oai-cn5g-fed/charts/oai-5g-ran
SERVER_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

echo "Configuring E2 on CU/DU conf files and /usr/local/etc/flexric/flexric.conf"
cat > /tmp/e2block <<EOF
      e2_agent = {
        near_ric_ip_addr = "$SERVER_IP";
        sm_dir = "/usr/local/lib/flexric/"
      }
EOF
cat /tmp/e2block >> $DIR_RAN_CHARTS/oai-cu/templates/configmap.yaml
cat /tmp/e2block >> $DIR_RAN_CHARTS/oai-du/templates/configmap.yaml

cat > /tmp/flexric.conf <<EOF
[NEAR-RIC]
NEAR_RIC_IP = $SERVER_IP

[XAPP]
DB_DIR = /tmp/

EOF
cat /tmp/flexric.conf > /usr/local/etc/flexric/flexric.conf
echo "cat /usr/local/etc/flexric/flexric.conf"
cat /usr/local/etc/flexric/flexric.conf

echo "tail cu conf:"
tail -8 $DIR_RAN_CHARTS/oai-cu/templates/configmap.yaml
echo "tail du conf:"
tail -8 $DIR_RAN_CHARTS/oai-du/templates/configmap.yaml
