NAME       := "csi-driver-nfs"
NAMESPACE  := "kube-system"
CHART_NAME := "csi-driver-nfs"
CHART_REPO := "csi-driver-nfs"
CHART_VERSION := "v3.1.0"


setup:
	helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

destroy:
	@echo "Deleting chart $(NAME) yaml with version $(VERSION) from $(CHART_REPO)/$(CHART_NAME) \
		into namespace $(NAMESPACE)"
	kubectl delete -n $(NAMESPACE) -f csi-driver-nfs.yaml

install: setup
	@echo "Installing chart $(NAME) yaml with version $(VERSION) from $(CHART_REPO)/$(CHART_NAME) \
		into namespace $(NAMESPACE)"
	helm template -n $(NAMESPACE) $(NAME) $(CHART_REPO)/$(CHART_NAME) --version $(CHART_VERSION) \
		--values values.yaml > csi-driver-nfs.yaml
	kubectl apply -n $(NAMESPACE) -f csi-driver-nfs.yaml
