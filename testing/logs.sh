#!/bin/bash

ns="oai5g" # Default namespace
nf="gnb" #Default OAI5G network function

usage()
{
   echo "Usage: $0 [-n namespace] [-f oai-function]"
   echo -e "\twith oai-function in {amf, ausf, smf, udr, udm, nrf, nssf, lmf, upf, gnb, cu, cu-cp, cu-up, du, nr-ue}"
   exit 1 
}

while getopts 'n:f:' flag; do
  case "${flag}" in
    n) ns="${OPTARG}" ;;
    f) nf="${OPTARG}" ;;
    *) usage
       exit 1 ;;
  esac
done

if [[ ($nf != "amf") && ($nf != "ausf") && ($nf != "smf") && ($nf != "udr") && ($nf != "udm") && ($nf != "nrf") && ($nf != "nssf") && ($nf != lmf) && ($nf != "upf") && ($nf != "gnb") && ($nf != "cu") && ($nf != "cu-cp") && ($nf != "cu-up") && ($nf != "du") && ($nf != "nr-ue") ]]; then
    usage
fi

echo "$0: Showing oai-${nf} pod logs on ${ns} namespace"

while true; do
    echo "Wait until oai-${nf} pod is Ready..." 
    while [[ $(kubectl -n $ns get pods -l app.kubernetes.io/name=oai-"${nf}" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
	sleep 1
    done

    # Retrieve the pod name
    POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-"${nf}" -o jsonpath="{.items[0].metadata.name}")

    echo "Show logs of "oai-${nf} pod $POD_NAME
    case $nf in
	"cu")
	    kubectl -n "$ns" -c "oai-${nf}" logs -f $POD_NAME ;;
	"du")
	    kubectl -n "$ns" -c "gnb${nf}" logs -f $POD_NAME ;;
	"cu-cp")
	    kubectl -n "$ns" -c "gnbcucp" logs -f $POD_NAME ;;
	"cu-up")
	    kubectl -n "$ns" -c "gnbcuup" logs -f $POD_NAME ;;
	*)
	    kubectl -n "$ns" -c "${nf}" logs -f $POD_NAME ;;
	esac
done
