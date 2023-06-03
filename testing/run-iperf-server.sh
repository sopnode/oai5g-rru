#!/bin/bash
# install and run iperf3 server on the spgwu-tiny pod

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

echo "$0: Install iperf3 on oai-spgwu-tiny pod, $ns namespace and run iperf3 -B 12.1.1.1 -s"

# create iperf3-server.sh installation script
cat > /tmp/iperf3-server.sh <<EOF
#!/bin/sh

# install and run iperf3 
apk update
apk add iperf3
/usr/bin/iperf3 -B 12.1.1.1 -s 
EOF
chmod a+x  /tmp/iperf3-server.sh

# retrieve spgwu-tiny pod name and copy iperf3-server.sh script there
SPGWU_POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-spgwu-tiny -o jsonpath="{.items[0].metadata.name}")

echo "kubectl -c tcpdump cp /tmp/iperf3-server.sh $ns/$SPGWU_POD_NAME:/iperf3-server.sh || true"
kubectl -c tcpdump cp /tmp/iperf3-server.sh $ns/$SPGWU_POD_NAME:/iperf3-server.sh || true

echo "kubectl -n $ns -c tcpdump exec -i $SPGWU_POD_NAME -- /bin/sh /iperf3-server.sh $ns"
kubectl -n $ns -c tcpdump exec -i $SPGWU_POD_NAME -- /bin/sh /iperf3-server.sh 


