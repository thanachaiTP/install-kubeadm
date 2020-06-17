#!/bin/bash

echo "apt add key"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo ""
echo "add sources.list kubernetes"
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
echo "--- Add sources.list Done ---"
sleep 5s


echo ""
echo "apt update and install kubeadm kubelet kubectl"
apt update && apt install -y kubelet kubeadm kubectl
echo "--- Install kubeadm kubelet kubectl Done ---"

sleep 1m

echo ""
echo "set netfilter"
echo "br_netfilter" >> /etc/modules-load.d/modules.conf
echo "--- Add netfilter Done ---"


echo ""
echo "sysctl k8s.conf"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "--- Config Sysctl Done ---"

echo ""
echo "set --fail-swap-on=false"
cp -f 10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload && systemctl restart kubelet.service
swapoff -a
echo "--- Config Swap Done ---"

echo ""
echo "--- Wait a Minute ---"
yes | kubeadm reset

echo "--- Let's to Create Cluster ---"
