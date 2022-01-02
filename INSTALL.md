# Setting up the Pi nodes

## Install and configure essential system packages

Below are some of the important parts. I ran these with tmux syncrhonized panes.

```bash
apt install ntp docker.io containerd sysstat etcd-client
systemctl enable ntp
sudo apt-get install net-tools
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo echo "vm.swappiness=0" | sudo tee --append /etc/sysctl.conf
sysctl -p
apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor > /usr/share/keyrings/cloud.google.gpg
echo "deb  http://apt.kubernetes.io/ kubernetes-impish main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get install -yq kubelet kubeadm kubectl kubernetes-cni
sudo apt-mark hold kubelet kubeadm kubectl
```

## Configure CRI

The following needs to be set for containerd.

```bash
containerd config default > /etc/containerd/config.toml # Set `SystemdCgroup = true` Reference: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
```

## Configure kubeadm

```bash
vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf Set `Environment="cgroup-driver=systemd/cgroup-driver=cgroupfs"` Reference: https://www.nakivo.com/blog/install-kubernetes-ubuntu/”cgroup-driver=systemd/cgroup-driver=cgroupfs”
```

## Configure Docker

```bash
cat <<EOF | sudo tee /etc/docker/daemon.json # https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

## Bootstrap with `kubeadm`

```bash
kubeadm init phase certs all --control-plane-endpoint cluster-endpoint
kubeadm config images pull --cri-socket=/var/run/containerd/containerd.sock -v 4 --kubernetes-version v1.23.sh controller0
kubeadm init --pod-network-cidr=10.0.0.0/8 --control-plane-endpoint=cluster-endpoint:6443 --cri-socket=/run/containerd/containerd.sock --ignore-preflight-errors=Mem --kubernetes-version v1.23.1 --upload-certs
kubeadm token create
kubeadm reset
kubeadm join cluster-endpoint:6443 --token 1aurfj.4sgw0ln0um5sjprz --discovery-token-ca-cert-hash sha256:e3304abcc71aa7f168e58a84e32497c34a5e03ceeb8d9bce1a62426d4b3a4460 --control-plane --certificate-key  e5ff0ebb48907b143b0441d7d2a1e73c6b2abab1c58055ad4e303511212f3f6e --cri-socket=/run/containerd/containerd.soc
kubeadm join cluster-endpoint:6443 --token 1aurfj.4sgw0ln0um5sjprz --discovery-token-ca-cert-hash sha256:e3304abcc71aa7f168e58a84e32497c34a5e03ceeb8d9bce1a62426d4b3a4460 --cri-socket=/run/containerd/containerd.sock
```
