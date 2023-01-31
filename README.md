# Installing kubeadm (Kubernetes)
> https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

### Install docker
```
# install -y apt-transport-https curl
# curl https://get.docker.com | sh
```

### Installing kubeadm, kubelet and kubectl
```
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
# cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
# apt update
# apt install -y kubelet kubeadm kubectl
# apt-mark hold kubelet kubeadm kubectl
```

### Config sysctl
```
# vim /etc/modules-load.d/modules.conf
br_netfilter

# cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
# sysctl --system
```

### Config swap on k8s at master and node
```
# vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --fail-swap-on=false"

# systemctl daemon-reload
# systemctl restart kubelet.service
# swapoff -a
```

### Config Cluster K8S at Master
> https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

> https://github.com/flannel-io/flannel#flannel

> https://kubernetes.io/docs/concepts/services-networking/network-policies/
```
# kubeadm reset
# kubeadm init --pod-network-cidr=10.244.0.0/16

# mkdir -p $HOME/.kube
# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# chown $(id -u):$(id -g) $HOME/.kube/config

# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

# export KUBECONFIG=/etc/kubernetes/admin.conf
# kubectl get pods --all-namespaces -o wide
```
For Kubernetes v1.17+ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


### Autocomplete
```
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

### Node master Shedule
```
# kubectl taint nodes --all node-role.kubernetes.io/master-
Node master NoSchedule
# kubectl taint nodes <name_nodes> node-role.kubernetes.io/master="":NoSchedule
```

### Install Web UI
> https://github.com/kubernetes/dashboard

#### recommended
```
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc3/aio/deploy/recommended.yaml
```

#### alternative
```
# kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc3/aio/deploy/alternative.yaml
```
#### Create sample user
>https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md

```
# vim dashboard-adminuser.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard

```
```
# kubectl apply -f dashboard-adminuser.yaml
```

#### Bearer Token
```
# kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```
#### Run Proxy
```
# kubectl proxy
OR
# kubectl proxy --address 0.0.0.0 --port=9999 --accept-hosts='^*$'
```

### Example Deployment
```
# git clone https://gitlab.com/workshop_docker_k8s/install-kubeadm.git install-kubeadm
# cd install-kubeadm
# kubectl apply -f nginx/deploy-nginx.yaml
```

### Install Helm
> https://helm.sh/docs/intro/install/

> https://www.digitalocean.com/community/tutorials/how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager
```
# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
OR
# cd /tmp
# curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh
# chmod u+x install-helm.sh
# ./install-helm.sh

# kubectl -n kube-system create serviceaccount tiller
# kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# helm init --service-account tiller
# kubectl get pods --namespace kube-system
```

### Install NFS-Client Provisioner
> https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client

- Install NFS Server
```
# apt install nfs-kernel-server -y
# mkdir -p /data/share
# chown nobody:nogroup /data/share

# vim /etc/exports
/data/share 192.168.1.0/24(rw,insecure,async,no_subtree_check,no_root_squash)
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

- Deploy PVC wordpress and mysql
```
# kubectl apply -f nfs-client-wp-claim.yaml
# kubectl apply -f nfs-client-db-claim.yaml
```
-  Change Permession and Owner Directory 
```
# cd /data/share/
# chown -R 999:docker default-nfs-client-db-claim-pvc-aee2d540-6175-44bc-a833-99f45151ae58
# chmod -R 755 default-nfs-client-db-claim-pvc-aee2d540-6175-44bc-a833-99f45151ae58
```

### Deploy wordpress and mysql
```
# kubectl apply -f secret-db.yaml
# kubectl apply -f mysql-deployment-pvc-nfs.yaml
# kubectl apply -f wordpress-deployment.yaml
# kubectl apply -f phpmyadmin.yaml
```
```
# kubectl get pods,svc -owide
```

### Using Kubernetes v1.20.0, getting "unexpected error getting claim reference: selfLink was empty
> https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/issues/25#issuecomment-742616668
```
# vim /etc/kubernetes/manifests/kube-apiserver.yaml
spec:
  containers:
  - command:
    - kube-apiserver
    
    Add this line:
    - --feature-gates=RemoveSelfLink=false

# kubectl apply -f /etc/kubernetes/manifests/kube-apiserver.yaml
# kubectl apply -f /etc/kubernetes/manifests/kube-apiserver.yaml
```
#### OR
```
# vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --fail-swap-on=false --feature-gates=RemoveSelfLink=false"

# systemctl daemon-reload
# systemctl restart kubelet.service
```

## How to Renew Certificate k8s

```
# kubeadm certs check-expiration
# kubeadm certs renew all --kubeconfig=/etc/kubernetes/admin.conf
# cp /etc/kubernetes/admin.conf /root/.kube/config
# systemctl restart docker
```

> https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-certs/

> https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/

> https://github.com/kubernetes/kubeadm/issues/581


## Reset k8s cluster
```
# kubeadm reset
# ifconfig cni0 down && ip link delete cni0
# ifconfig flannel.1 down && ip link delete flannel.1
# rm -rf /var/lib/cni/
```

## Configuring flannel to use a non default interface in kubernetes
> https://stackoverflow.com/questions/47845739/configuring-flannel-to-use-a-non-default-interface-in-kubernetes

If you download the kube-flannel.yml file, you should look at DaemonSet spec, specifically at the "kube-flannel" container. There, you should add the required "--iface=enp0s8" argument (Don't forget the "="). Part of the code I've used.
```
# wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
# vim kube-flannel.yml

  containers:
  - name: kube-flannel
    image: quay.io/coreos/flannel:v0.10.0-amd64
    command:
    - /opt/bin/flanneld
    args:
    - --ip-masq
    - --kube-subnet-mgr
    - --iface=enp0s8

# kubectl apply -f kube-flannel.yml
```

## วิธีเรียกใช้งานชื่อ services ภายใน k8s
> https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

การเรียกชื่อหรือการเชื่อมต่อผ่านชื่อภายใน k8s services 
```
nginx.default.svc.cluster.local
```
| Name          | Descriptions             |
|---------------|--------------------------|
| nginx         | คือชื่อ services            |
| default       | คือ namespaces            |
| svc           | คือ services              |
| cluster.local | คือ default dns ภายใน k8s | 


## k8s delete all pods with status 'Evicted'
```
# kubectl get pods -owide | grep Evicted | awk '{print $1}' | xargs kubectl delete pod --grace-period=0 --force
```
