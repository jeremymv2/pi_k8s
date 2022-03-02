KUBE_CONTEXT = kubernetes-admin@pi-k8s
K8S_VERSION = v1.23.1
CONTROL_PLANE_API = cluster-endpoint:6443
CLUSTER_NAME = pi-k8s
CRI_SOCKET = unix:///run/containerd/containerd.sock
LOG_LEVEL = 6
K8S_SERVICE_CIDR = 10.250.0.0/16
K8S_POD_NET_CIDR = 10.251.0.0/16
CALICO_BLOCKSIZE = 22 # 65 workers with 1024 PODs each
# hostnames
CONTROLLER0 = controller0
CONTROLLER1 = controller1
CONTROLLER2 = controller2
WORKER0 = worker0
WORKER1 = worker1
WORKER2 = worker2
CONTROLLER1_ADVERTISE_IP = 172.16.0.246
CONTROLLER2_ADVERTISE_IP = 172.16.0.103
ALL_WORKERS = $(WORKER2) $(WORKER1) $(WORKER0)
ALL_CONTROLLERS = $(CONTROLLER2) $(CONTROLLER1) $(CONTROLLER0)
this_path := $(abspath $(firstword $(MAKEFILE_LIST)))
this_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))
INIT = $(this_dir)installed/init
METALLB = $(this_dir)installed/metallb
MONITORING = $(this_dir)installed/prometheus
LOGGING = $(this_dir)installed/fluentbit
FLANNEL = $(this_dir)installed/flannel
CALICO = $(this_dir)installed/calico
NFS_CSI = $(this_dir)installed/nfs_storage
CNI_IN_USE = calico
CSI_IN_USE = nfs_storage
TMP_CONFIG := $(shell mktemp /tmp/abc-script.XXXXXX)

export K8S_VERSION CONTROL_PLANE_API CLUSTER_NAME K8S_SERVICE_CIDR K8S_POD_NET_CIDR CRI_SOCKET \
  KUBE_CONTEXT CALICO_BLOCKSIZE ALL_WORKERS ALL_CONTROLLERS CONTROLLER0 K8S_SERVICE_CIDR

ansible:
	ansible-playbook ansible-playbook.yaml

$(INIT):
	@echo "-------------------------------"
	@echo " INITIALIZING $(CONTROLLER0)"
	@echo "-------------------------------"
	ssh $(CONTROLLER0) sudo systemctl restart containerd
	ssh $(CONTROLLER0) sudo rm -rf /etc/kubernetes
	ssh $(CONTROLLER0) sudo rm -rf /etc/calico
	ssh $(CONTROLLER0) sudo mkdir /etc/kubernetes
	envsubst < ./templates/kubeadm_init_config.yaml > $(TMP_CONFIG)
	scp $(TMP_CONFIG) root@$(CONTROLLER0):/etc/kubernetes/kubeadm_config.yaml
	ssh $(CONTROLLER0) sudo kubeadm init phase certs all \
		--v=$(LOG_LEVEL) \
		--config=/etc/kubernetes/kubeadm_config.yaml
	ssh $(CONTROLLER0) sudo kubeadm init \
		--skip-phases certs \
		--v=$(LOG_LEVEL) \
		--config=/etc/kubernetes/kubeadm_config.yaml \
		--upload-certs
	ssh $(CONTROLLER0) "until sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes -o wide 2>/dev/null ; \
		do sleep 5 ; \
		  echo 'Waiting for successful reponse from the K8S API..' ; \
		done"
	ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf \
		label node $(CONTROLLER0) kubernetes.io/role=master
	for node in $(CONTROLLER1_ADVERTISE_IP) $(CONTROLLER2_ADVERTISE_IP); do \
		echo "---------------------------------------" ; \
		echo " JOINING $$node TO CONTROL PLANE" ; \
		echo "---------------------------------------" ; \
		ssh $$node sudo systemctl restart containerd ; \
		ssh $$node sudo rm -rf /etc/kubernetes ; \
		ssh $$node sudo rm -rf /etc/calico ; \
		ssh $$node sudo mkdir /etc/kubernetes ; \
		export ADVERTISE_IP=$$node ; \
		envsubst < ./templates/kubeadm_controller_join_config.yaml > $(TMP_CONFIG) ; \
		scp $(TMP_CONFIG) root@$$node:/etc/kubernetes/kubeadm_config.yaml ; \
		ssh $$node sudo systemctl restart containerd ; \
		scp -r root@$(CONTROLLER0):/etc/kubernetes/pki root@$$node:/etc/kubernetes/ ; \
		scp root@$(CONTROLLER0):/etc/kubernetes/admin.conf root@$$node:/etc/kubernetes/ ; \
		ssh $$node sudo kubeadm join $(CONTROLLER0):6443 \
		  --v=$(LOG_LEVEL) \
		  --config=/etc/kubernetes/kubeadm_config.yaml ; \
		ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o wide ; \
	done
	ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o wide
	./util/etcd/etcdstatus.sh
	for node in $(ALL_WORKERS); do \
		echo "---------------------------------------" ; \
		echo " JOINING WORKER $$node" ; \
		echo "---------------------------------------" ; \
		ssh $$node sudo systemctl restart containerd ; \
		ssh $$node sudo rm -rf /etc/kubernetes ; \
		ssh $$node sudo mkdir /etc/kubernetes ; \
		envsubst < ./templates/kubeadm_worker_join_config.yaml > $(TMP_CONFIG) ; \
		scp $(TMP_CONFIG) root@$$node:/etc/kubernetes/kubeadm_config.yaml ; \
		scp root@$(CONTROLLER0):/etc/kubernetes/admin.conf root@$$node:/etc/kubernetes/ ; \
		ssh $$node sudo systemctl restart containerd ; \
		ssh $$node sudo kubeadm join $(CONTROLLER0):6443 \
		  --v=$(LOG_LEVEL) \
		  --config=/etc/kubernetes/kubeadm_config.yaml ; \
		ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf \
			label node $$node node-role.kubernetes.io/worker=worker ; \
		ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o wide ; \
	done
	ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf \
			label node $(CONTROLLER1) kubernetes.io/role=master
	ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf \
			label node $(CONTROLLER2) kubernetes.io/role=master
	ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf create ns tests
	ssh $(CONTROLLER0) sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o wide
	touch $(INIT)

generate-kubeconfig:
	@ssh $(CONTROLLER0) "mkdir -p \$HOME/.kube && \
		sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config && \
		sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

install_cni: $(CNI_IN_USE)

install_csi: $(CSI_IN_USE)

install: $(INIT)
	$(MAKE) kubeconfig
	$(MAKE) install_cni
	$(MAKE) install_csi

uninstall_cni: uninstall_$(CNI_IN_USE)

uninstall_csi: uninstall_$(CSI_IN_USE)

nuke:
	$(MAKE) uninstall_cni
	$(MAKE) uninstall_csi
	for node in $(ALL_WORKERS) $(ALL_CONTROLLERS); do \
		echo "-----------------------------" ; \
		echo " DESTROYING K8S ON $$node" ; \
		echo "-----------------------------" ; \
		scp files/cleanup.sh root@$$node:/tmp ; \
		ssh root@$$node chmod a+x /tmp/cleanup.sh ; \
		ssh root@$$node /tmp/cleanup.sh all ; \
	done
	rm -f installed/*
	rm -f $(INIT)

kubeconfig:
	@ssh $(CONTROLLER0) sudo cat /etc/kubernetes/admin.conf | tee ~/.kube/config

$(CALICO):
	pushd namespaces/kube-system/calico && \
		$(MAKE) apply && popd
	touch $(CALICO)

calico: $(CALICO)

uninstall_calico:
	pushd namespaces/kube-system/calico && \
		$(MAKE) uninstall && popd
	rm -f $(CALICO)

$(NFS_CSI):
	pushd namespaces/kube-system/csi-driver-nfs && \
		$(MAKE) apply && popd
	touch $(NFS_CSI)

nfs_storage: $(NFS_CSI)

uninstall_nfs_storage:
	pushd namespaces/kube-system/csi-driver-nfs && \
		$(MAKE) destroy && popd
	rm -f $(NFS_CSI)

metallb: $(METALLB)

uninstall_metallb:
	pushd namespaces/metallb-system && \
		$(MAKE) uninstall && popd
	rm -f $(METALLB)

$(METALLB):
	pushd namespaces/metallb-system && \
		$(MAKE) apply && popd
	touch $(METALLB)

monitoring: $(MONITORING)

uninstall_monitoring:
	pushd namespaces/monitoring/prometheus && \
		$(MAKE) uninstall && popd

$(MONITORING):
	pushd namespaces/monitoring/prometheus && \
		$(MAKE) apply && popd
	touch $(MONITORING)

logging: $(LOGGING)

uninstall_logging:
	pushd namespaces/logging/fluent-bit && \
		$(MAKE) uninstall && popd

$(LOGGING):
	pushd namespaces/logging/fluent-bit && \
		$(MAKE) apply && popd
	touch $(LOGGING)

alltherest: metallb monitoring logging
