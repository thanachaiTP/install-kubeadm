# Deployment Wordpress and Mysql

## Deploy Local PV
```
# kubectl apply -f local-volumes.yaml
```

## Deploy Secret and Mysql
```
# kubectl apply -f secret-db.yaml
# kubectl apply -f mysql-deployment.yaml
```

## Deploy Wordpress
```
# kubectl apply -f wordpress-deployment.yaml
```
