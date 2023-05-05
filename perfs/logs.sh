#!/bin/bash

ns="oai5g" # Default namespace

usage()
{
   echo "Usage: $0 oai-function"
   echo -e "\twhere oai-function in [amf, gnb, nr-ue]"
   exit 1
}

if [ $# -ne 1 ]; then
    usage
else
    oaiLabel="$1"
    if [[ ($oaiLabel != "amf") && ($oaiLabel != "gnb") && ($oaiLabel != "nr-ue") ]]; then
       usage
    fi
fi


echo "Wait until oai-${oaiLabel} pod is Ready..."
while [[ $(kubectl -n $ns get pods -l app.kubernetes.io/name=oai-"${oaiLabel}" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 1
done

# Retrieve the pod name
POD_NAME=$(kubectl -n$ns get pods -l app.kubernetes.io/name=oai-"${oaiLabel}" -o jsonpath="{.items[0].metadata.name}")

echo "Show logs of "oai-${oaiLabel} pod $POD_NAME
kubectl -n "$ns" -c "${oaiLabel}" logs -f $POD_NAME