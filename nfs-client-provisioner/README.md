# Install NFS-Client Provisioner
> https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client

- Install NFS Server
```
# apt install nfs-kernel-server -y
# mkdir -p /data/share
# chown nobody:nogroup /data/share

# vim /etc/exports
/data/share 192.168.1.0/24(rw,sync,no_subtree_check)
# exportfs -a
# systemctl restart nfs-kernel-server
```
-  Configuring the Client Machine
```
# apt install nfs-common -y 
```
- NFS-Client Provisioner
```
# helm install --name nfs-client-provisioner --values nfs-client-value.yaml stable/nfs-client-provisioner
# kubectl create -f nfs-client-pvc.yaml
# helm upgrade nfs-client-provisioner --values nfs-client-values.yaml stable/nfs-client-provisioner
```
