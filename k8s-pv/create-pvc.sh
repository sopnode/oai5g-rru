#!/bin/bash
NS=${1:-'oai5g'}

kubectl -n"$NS" apply -f pvc-cn5g.yaml
kubectl -n"$NS" apply -f pvc-ran5g.yaml
