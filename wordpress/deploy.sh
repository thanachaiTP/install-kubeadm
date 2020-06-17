#!/bin/bash
echo "-----------------------"
echo "|   Start Deployment  |" 
echo "-----------------------"
echo ""
kubectl get pv,pvc,pods,svc -owide

kubectl apply -f local-volumes.yaml
kubectl apply -f secret-db.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f wordpress-deployment.yaml

sleep 10
echo ""
kubectl get pv,pvc,pods,svc -owide

echo "-----------------"
echo "|     Finish    |"
echo "-----------------"
