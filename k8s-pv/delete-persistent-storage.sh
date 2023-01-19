#!/bin/bash
NS=${1:-'oai5g'}

kubectl -n"$NS" delete pvc cn5g-pvc
kubectl -n"$NS" delete pvc ran5g-pvc
kubectl delete pv cn5g-pv
kubectl delete pv ran5g-pv
