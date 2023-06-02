#!/bin/bash
# run iperf3 client on a fit node connected to Quectel

ip_server="12.1.1.1"
duration="10"
udp_rate="100M"
nif="wwan0"
reverse_mode=""
sim_mode=""
quectel_node=""
ns=""

usage()
{
   echo "Usage: $0 -n namespace [-f fitXX | -s]  [-t duration] [-b UDP rate] [-i wireless_interface] [-R]"
   echo -e "\tLaunch iperf3 client on UE (nr-ue pod or fit node with Quectel)"
   exit 1
}

while getopts 'n:f:t:b:i:Rs' flag; do
  case "${flag}" in
    n) ns="${OPTARG}" ;;
    f) quectel_node="${OPTARG}" ;;
    t) duration="${OPTARG}" ;;
    b) udp_rate="${OPTARG}" ;;
    i) nif="${OPTARG}" ;;
    R) reverse_mode="-R" ;;
    s) sim_mode="true" ;;
    *) usage ;;
  esac
done

if [ -z "$quectel_node" ] && [ -z "$sim_mode" ]; then
    usage
fi
if [ -z "$ns" ]; then
    usage
fi

if [ -z "$sim_node" ]; then
    # UE is a fit node connected to a Quectel device
    ip_client=$(ssh $quectel_node ifconfig $nif |grep "inet " | awk '{print $2}')
    iperf_options="-c $ip_server -B $ip_client -u -b $udp_rate $reverse_mode -t $duration"

    echo "Running iperf3 client on $quectel_node with following options:"
    echo "$iperf_options"

    echo "ssh -o StrictHostKeyChecking=no $quectel_node /usr/bin/iperf3 $iperf_options"
    ssh -o StrictHostKeyChecking=no $quectel_node /usr/bin/iperf3 $iperf_options
else
    # UE is the oai-nr-ue pod, rfsim mode
    # Retrieve nr-ue pod name
    NRUE_POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-nr-ue -o jsonpath="{.items[0].metadata.name}")
    # Retrieve the IP address of the 5G interface
    ip_client=$(kubectl -n $ns -c tcpdump exec -i $NRUE_POD_NAME -- ifconfig oaitun_ue1 | perl -nle 's/dr:(\S+)/print $1/e')
    # create iperf3-client.sh installation script
    iperf_options="-c $ip_server -B $ip_client -u -b $udp_rate $reverse_mode -t $duration"
    echo "Running iperf3 client on $NRUE_POD_NAME with following options:"
    echo "$iperf_options"
    cat > /tmp/iperf3-client.sh <<EOF
#!/bin/sh

# install and run iperf3 client  
apk update
apk add iperf3
/usr/bin/iperf3 $iperf_options
EOF
    chmod a+x  /tmp/iperf3-client.sh

    echo "kubectl -n $ns tcpdump exec -i $NRUE_POD_NAME -- /bin/sh /iperf-client.sh"
    kubectl -n $ns tcpdump exec -i $NRUE_POD_NAME -- /bin/sh /iperf-client.sh 
fi


#nota: perf obtained so far
#110M on fit07, less on fit09
