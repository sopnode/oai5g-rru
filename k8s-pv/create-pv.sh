#!/bin/bash
DIR=$(pwd)

kubectl apply -f $DIR/pv-cn5g.yaml
kubectl apply -f $DIR/pv-ran5g.yaml
