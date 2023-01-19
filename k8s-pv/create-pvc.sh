#!/bin/bash
NS=${1:-'oai5g'}
DIR=$(pwd)

kubectl -n"$NS" apply -f $DIR/pvc-cn5g.yaml
kubectl -n"$NS" apply -f $DIR/pvc-ran5g.yaml
