#!/bin/bash
bx login -a api.ng.bluemix.net
bx cs init --host https://us-south.containers.bluemix.net
bx cs cluster-create --name my_cluster
bx cs cluster-config my_cluster >kube_env.txt
sh ./kube_env.txt
kubectl apply -f bx-kube-replicat.yaml
kubectl apply -f bx-kube-service.yaml

