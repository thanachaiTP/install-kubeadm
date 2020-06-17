#!/bin/bash
echo "---------------------------------"
echo "|   Start Terminate Deployment  |"
echo "---------------------------------"
kubectl delete -f wordpress-deployment.yaml
kubectl delete -f mysql-deployment.yaml
kubectl delete -f secret-db.yaml
kubectl delete -f local-volumes.yaml
echo ""

sleep 5
kubectl get pv,pvc,pods,svc

rm -rf /tmp/data
echo "---------------------------"
echo "|     Terminate Finish    |"
echo "---------------------------"
