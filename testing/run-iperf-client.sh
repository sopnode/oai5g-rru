#!/bin/bash
# run iperf3 client on a node connected to Quectel (either a fit node or a qhat node)

ip_server="12.1.1.1"
quectel_nif="wwan0"
sim_mode=""
quectel_node=""
ns=""
default_args="-u -b 10M -t 10"
iperf3_args=""

usage()
{
   echo "Usage: $0 -n namespace [-f [fitXX | qhatXX] | -s]  [-o ' iperf3_arguments ... ']"
   echo -e "\tLaunch iperf3 client on UE (nr-ue pod or fit node with Quectel)"
   echo -e "\tdefault iperf3 client options are: $default_args"
   echo -e "\tuse -o to use your own iperf3 options"
   exit 1
}

while getopts 'n:f:o:s' flag; do
  case "${flag}" in
    n) ns="${OPTARG}" ;;
    s) sim_mode="true" ;;
    f) quectel_node="${OPTARG}" ;;
    o) iperf3_args="${OPTARG}" ;;
    *) usage ;;
  esac
done

if [ -z "$quectel_node" ] && [ -z "$sim_mode" ]; then
    usage
fi
if [ -z "$ns" ]; then
    usage
fi
if [ -z "$iperf3_args" ]; then
    iperf3_args="$default_args"
fi

if [ -z "$sim_mode" ]; then
    # UE is a fit node connected to a Quectel device
    ip_client=$(ssh $quectel_node ifconfig $quectel_nif |grep "inet " | awk '{print $2}')
    iperf_options="-c $ip_server -B $ip_client $iperf3_args"

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
    iperf_options="-c $ip_server -B $ip_client $iperf3_args"
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
    echo "kubectl -c tcpdump cp /tmp/iperf3-client.sh $ns/$NRUE_POD_NAME:/iperf3-client.sh"
    kubectl -c tcpdump cp /tmp/iperf3-client.sh $ns/$NRUE_POD_NAME:/iperf3-client.sh || true

    echo "kubectl -n $ns -c tcpdump exec -i $NRUE_POD_NAME -- /bin/sh /iperf3-client.sh"
    kubectl -n $ns -c tcpdump exec -i $NRUE_POD_NAME -- /bin/sh /iperf3-client.sh 
fi


#nota: perf obtained so far
#110M on fit07, less on fit09
