# Deployment Wordpress and Mysql

## Deploy Local PV (hostPath)
```
# kubectl apply -f local-volumes.yaml
```

## Deploy Secret and Mysql (nfs-provisioner)
```
# kubectl apply -f secret-db.yaml
# kubectl apply -f mysql-deployment-pvc-nfs.yaml
```

## Deploy Wordpress (nfs-provisioner)
```
# kubectl apply -f wordpress-deployment.yaml
```
