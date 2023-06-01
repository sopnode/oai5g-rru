#!/bin/bash
# run iperf3 client on a fit node connected to Quectel

ip_server="12.1.1.1"
duration="10"
udp_rate="100M"
nif="wwan0"
reverse_mode=""
quectel_node=""

usage()
{
   echo "Usage: $0 -f fitXX [-t duration] [-b UDP rate] [-i wireless_interface] [-R]"
   echo -e "\tLaunch iperf3 client on the fit node that hosts UE Quectel"
   exit 1
}

while getopts 'f:t:b:i:R' flag; do
  case "${flag}" in
    f) quectel_node="${OPTARG}" ;;
    t) duration="${OPTARG}" ;;
    b) udp_rate="${OPTARG}" ;;
    i) nif="${OPTARG}" ;;
    R) reverse_mode="-R" ;;
    *) usage
       exit 1 ;;
  esac
done

if [ -z "$quectel_node" ]; then
    usage
fi

ip_client=$(ssh $quectel_node ifconfig $nif |grep "inet " | awk '{print $2}')
iperf_options="-c $ip_server -B $ip_client -u -b $udp_rate $reverse_mode -t $duration"

echo "Running iperf3 client on $quectel_node with following options:"
echo "$iperf_options"

echo "ssh -o StrictHostKeyChecking=no $quectel_node /usr/bin/iperf3 $iperf_options"
ssh -o StrictHostKeyChecking=no $quectel_node /usr/bin/iperf3 $iperf_options


#nota: perf obtained so far
#110M on fit07, less on fit09
