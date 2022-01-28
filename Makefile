K8S_VERSION = v1.23.1
K8S_SERVICE_CIDR = 172.16.100.0/23
K8S_POD_NET_CIDR = 172.16.200.0/20 # 4094 PODs
CALICO_BLOCKSIZE = /22 # 4 workers with 1022 PODs each
CONTROLLER0 = pi4-1
CONTROLLER1 = pi4-2
CONTROLLER2 = pi4-3
WORKER0 = pi4-0
WORKER1 = pi3-0
WORKER2 = pi3-1
ALL_WORKERS = $(WORKER2) $(WORKER1) $(WORKER0)
ALL_CONTROLLERS = $(CONTROLLER2) $(CONTROLLER1) $(CONTROLLER0)
this_path := $(abspath $(firstword $(MAKEFILE_LIST)))
this_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))
INIT = $(this_dir)installed/init
METALLB = $(this_dir)installed/metallb
MONITORING = $(this_dir)installed/prometheus
LOGGING = $(this_dir)installed/fluentbit
FLANNEL = $(this_dir)installed/flannel

export KUBE_CONTEXT

initialize: $(INIT)

$(INIT):
	@ssh $(CONTROLLER0) sudo systemctl restart containerd
	@ssh $(CONTROLLER0) sudo kubeadm init phase certs all \
		--v=5 \
		--control-plane-endpoint=cluster-endpoint:6443 \
		--kubernetes-version=$(K8S_VERSION)
	@ssh $(CONTROLLER0) sudo kubeadm init \
		--v=5 \
		--apiserver-bind-port=6443 \
		--cert-dir=/etc/kubernetes/pki \
		--service-cidr=$(K8S_SERVICE_CIDR) \
		--pod-network-cidr=$(K8S_POD_NET_CIDR) \
		--control-plane-endpoint=cluster-endpoint:6443 \
		--cri-socket=/run/containerd/containerd.sock \
		--kubernetes-version=$(K8S_VERSION) \
		--upload-certs
	@ssh $(CONTROLLER0) "until sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes 2>/dev/null ; \
		do sleep 5 ; \
		  echo 'Waiting for successful reponse from the K8S API..' ; \
		done"
	@echo "-------------------------------"
	@echo " $(CONTROLLER0) INITIALIZED! "
	@echo "-------------------------------"
	@for node in $(CONTROLLER1) $(CONTROLLER2); do \
		echo "-----------------------------" ; \
		echo " JOINING K8S ON $$node" ; \
		echo "-----------------------------" ; \
		ssh $$node sudo systemctl restart containerd ; \
		ssh $$node sudo $$(ssh $(CONTROLLER0) sudo kubeadm token create --print-join-command) ; \
	done
	@for node in controller1 controller2; do \
		echo "-----------------------------" ; \
		echo " ADDING ROLES ON $$node" ; \
		echo "-----------------------------" ; \
		ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf \
			label node $$node node-role.kubernetes.io/control-plane=control-plane \
			node-role.kubernetes.io/master=master ; \
		ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes ; \
	done
	@touch $(INIT)

generate-kubeconfig:
	@ssh $(CONTROLLER0) "mkdir -p \$HOME/.kube && \
		sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config && \
		sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

system-critical: initialize flannel metallb monitoring logging

#@for node in $(ALL_WORKERS) $(ALL_CONTROLLERS); do \

destroy:
	@for node in $(ALL_CONTROLLERS); do \
		echo "-----------------------------" ; \
		echo " DESTROYING K8S ON $$node" ; \
		echo "-----------------------------" ; \
		ssh $$node sudo kubeadm reset \
			--cri-socket=/var/run/containerd/containerd.sock \
			--force \
			--v=5 \
			--kubeconfig ~ubuntu/.kube/config ; \
		ssh $$node sudo rm -rf /var/run/containerd /etc/cni/net.d/* ; \
		ssh $$node sudo crictl --runtime-endpoint /run/containerd/containerd.sock ps || true ; \
		ssh $$node sudo iptables -F ; \
		ssh $$node sudo ipvsadm --clear ; \
	done
	@rm -f $(INIT)

metallb: $(METALLB)

metallb-uninstall:
	@pushd namespaces/metallb-system && \
		$(MAKE) uninstall && popd

$(METALLB):
	@pushd namespaces/metallb-system && \
		$(MAKE) apply && popd
	@touch $(METALLB)

monitoring: $(MONITORING)

monitoring-uninstall:
	@pushd namespaces/monitoring/prometheus && \
		$(MAKE) uninstall && popd

$(MONITORING):
	@pushd namespaces/monitoring/prometheus && \
		$(MAKE) apply && popd
	@touch $(MONITORING)

logging: $(LOGGING)

logging-uninstall:
	@pushd namespaces/logging/fluent-bit && \
		$(MAKE) uninstall && popd

$(LOGGING):
	@pushd namespaces/logging/fluent-bit && \
		$(MAKE) apply && popd
	@touch $(LOGGING)

