include ../../../Makefile

RELEASE_NAME  := csi-driver-nfs
NAMESPACE  := kube-system
CHART_NAME := csi-driver-nfs
CHART_REPO := csi-driver-nfs
CHART_VERSION := v3.1.0
REPO_URL   := https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
NFS_SERVER := 192.168.1.201
NFS_PATH   := /k8s/provisioner
PROVISIONER_NAME := pik8s.ethzero.cloud/nfs

export NFS_SERVER NFS_PATH PROVISIONER_NAME

setup:
	helm repo add $(CHART_REPO) $(REPO_URL)

destroy:
	@echo "Deleting chart $(RELEASE_NAME) yaml with version $(VERSION) from $(CHART_REPO)/$(CHART_NAME) into namespace $(NAMESPACE)"
	kubectl delete -n $(NAMESPACE) -f 01_$(RELEASE_NAME).yaml --context $(KUBE_CONTEXT)
	envsubst < 02_nfs-auto-provisioner.yaml | kubectl delete --context $(KUBE_CONTEXT) -n $(NAMESPACE) -f -
	rm -f ../../../installed/nfs_storage

apply: setup
	@echo "Installing chart $(RELEASE_NAME) yaml with version $(VERSION) from $(CHART_REPO)/$(CHART_NAME) \
		into namespace $(NAMESPACE)"
	helm template -n $(NAMESPACE) $(RELEASE_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--version $(CHART_VERSION) \
		--values values.yaml > 01_$(RELEASE_NAME).yaml
	kubectl apply -n $(NAMESPACE) -f 01_$(RELEASE_NAME).yaml --context $(KUBE_CONTEXT)
	envsubst < 02_nfs-auto-provisioner.yaml | kubectl apply --context $(KUBE_CONTEXT) -n $(NAMESPACE) -f -
	touch ../../../installed/nfs_storage

tests:
	kubectl apply -f test-pvc.yaml --context $(KUBE_CONTEXT)
