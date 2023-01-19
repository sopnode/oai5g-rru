#!/bin/bash
NS=${1:-'oai5g'}

kubectl apply -f pv-cn5g.yaml
kubectl apply -f pv-ran5g.yaml
kubectl -n"$NS" apply -f pvc-cn5g.yaml
kubectl -n"$NS" apply -f pvc-ran5g.yaml
