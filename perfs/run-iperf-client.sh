#!/bin/bash
# run iperf3 client on a fit node connected to Quectel

ip_server="12.1.1.1"
duration="10"
udp_rate="100M"

usage()
{
   echo "Usage: $0 fitXX"
   echo -e "\tLaunch iperf3 client on fit node on the wwan0 interface"
   exit 1
}

if [ $# -ne 1 ]; then
    usage
else
    quectel_node="$1"
fi

ip_client=$(ssh $quectel_node ifconfig wwan0 |grep "inet " | awk '{print $2}')

echo "ssh -o StrictHostKeyChecking=no $quectel_node /usr/bin/iperf3 -c $ip_server -B $ip_client -b $udp_rate -u -R -t $duration"
ssh -o StrictHostKeyChecking=no $quectel_node /usr/bin/iperf3 -c $ip_server -B $ip_client -b $udp_rate -u -R -t $duration


#nota: perf obtained so far
#110M on fit07, less on fit09
