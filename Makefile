KUBE_CONTEXT ?= kubernetes-admin@kubernetes
CONTROLLER01 = pi4-1
CONTROLLER02 = pi4-2
CONTROLLER03 = pi4-3
this_path := $(abspath $(firstword $(MAKEFILE_LIST)))
this_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))
METALLB = $(this_dir)installed/metallb
MONITORING = $(this_dir)installed/prometheus
LOGGING = $(this_dir)installed/fluentbit
FLANNEL = $(this_dir)installed/flannel

export KUBE_CONTEXT

init:
	@ssh $(CONTROLLER0) kubeadm init phase certs all \
		--control-plane-endpoint cluster-endpoint
	@ssh $(CONTROLLER0) kubeadm config images pull \
		--cri-socket=/var/run/containerd/containerd.sock \
		-v 4 \
		--kubernetes-version v1.23.1
	@ssh $(CONTROLLER0) kubeadm init \
		--service-cidr=10.96.0.0/16 \
		--pod-network-cidr=10.244.0.0/16 \
		--control-plane-endpoint=cluster-endpoint:6443 \
		--cri-socket=/run/containerd/containerd.sock \
		--kubernetes-version v1.23.1 \
		--upload-certs

destroy:
	@ssh $(CONTROLLER0) kubeadm reset

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

launch: flannel metallb monitoring logging
