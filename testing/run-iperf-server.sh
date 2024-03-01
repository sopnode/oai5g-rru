#!/bin/bash
# install and run iperf3 server on the upf pod

ns="" 

usage()
{
   echo "Usage: $0 -n namespace"
   echo -e "\tLaunch iperf3 server on oai-spwgu-tiny pod"
   exit 1
}

while getopts 'n:' flag; do
  case "${flag}" in
    n) ns="${OPTARG}" ;;
    *) usage ;;
  esac
done

if [ -z "$ns" ]; then
    usage
fi

echo "$0: Install iperf3 on oai-upf pod, $ns namespace and run iperf3 -B 12.1.1.1 -s"

# create iperf3-server.sh installation script
cat > /tmp/iperf3-server.sh <<EOF
#!/bin/sh

# install and run iperf3 
apk update
apk add iperf3
/usr/bin/iperf3 -B 12.1.1.1 -s 
EOF
chmod a+x  /tmp/iperf3-server.sh

# retrieve upf pod name and copy iperf3-server.sh script there
UPF_POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-upf -o jsonpath="{.items[0].metadata.name}")

echo "kubectl -c tcpdump cp /tmp/iperf3-server.sh $ns/$UPF_POD_NAME:/iperf3-server.sh || true"
kubectl -c tcpdump cp /tmp/iperf3-server.sh $ns/$UPF_POD_NAME:/iperf3-server.sh || true

echo "kubectl -n $ns -c tcpdump exec -i $UPF_POD_NAME -- /bin/sh /iperf3-server.sh $ns"
kubectl -n $ns -c tcpdump exec -i $UPF_POD_NAME -- /bin/sh /iperf3-server.sh 


