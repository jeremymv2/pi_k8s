RELEASE_NAME  := csi-driver-nfs
K8S_CONTEXT := kubernetes-admin@pi-k8s
NAMESPACE  := kube-system
CHART_NAME := csi-driver-nfs
CHART_REPO := csi-driver-nfs
CHART_VERSION := v3.1.0
REPO_URL   := https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"


setup:
	helm repo add $(CHART_REPO) $(REPO_URL)

destroy:
	@echo "Deleting chart $(RELEASE_NAME) yaml with version $(VERSION) from $(CHART_REPO)/$(CHART_NAME) \
		into namespace $(NAMESPACE)"
	kubectl delete -n $(NAMESPACE) -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT)

install: setup
	@echo "Installing chart $(RELEASE_NAME) yaml with version $(VERSION) from $(CHART_REPO)/$(CHART_NAME) \
		into namespace $(NAMESPACE)"
	helm template -n $(NAMESPACE) $(RELEASE_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--context $(K8S_CONTEXT) \
		--version $(CHART_VERSION) \
		--values values.yaml > $(RELEASE_NAME).yaml
	kubectl apply -n $(NAMESPACE) -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT)
