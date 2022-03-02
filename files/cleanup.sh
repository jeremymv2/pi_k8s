#!/usr/bin/env bash

set -x

if [[ $1 == all ]]; then
  sudo kubeadm reset \
    --cri-socket=unix:///run/containerd/containerd.sock \
    --force \
    --v=5 \
    --kubeconfig /etc/kubernetes/admin.conf || true
  sudo rm -rf /var/run/containerd || true
  sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps || true
fi

sudo rm -rf /etc/calico || true
for file in /etc/cni/net.d/*calico*; do
  echo "Deleting file: $file"
  sudo rm -f "$file"
done
for file in /etc/cni/net.d/*flannel*; do
  echo "Deleting file: $file"
  sudo rm -f "$file"
done

sudo ipvsadm --clear || true
sudo iptables -F || true
sudo ip link del cni0 || true

for link in $(ip link show | grep veth | awk '{print $2}' | awk -F@ '{print $1}'); do
  echo "Deleting $link"
  sudo ip link del "$link"
done
