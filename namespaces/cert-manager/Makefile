CHART_VERSION := v1.7.1
K8S_CONTEXT := kubernetes-admin@pi-k8s
CHART_NAME := cert-manager
NAMESPACE  := $(CHART_NAME)
CHART_REPO := jetstack
RELEASE_NAME := $(CHART_NAME)-$(shell echo $(CHART_VERSION) | sed -e 's/\./\-/g')
REPO_URL := https://charts.jetstack.io
CMCTL = cmctl.tar.gz

$(CMCTL):
	@echo "Downloading cmctl"
	OS=$$(go env GOOS) ; \
	   ARCH=$$(go env GOARCH) ; \
	   curl -sSL -o cmctl.tar.gz https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cmctl-$$OS-$$ARCH.tar.gz
	tar xzf cmctl.tar.gz
	sudo mv cmctl /usr/local/bin


setup: $(CMCTL)
	helm repo add $(CHART_REPO) $(REPO_URL)
	helm repo update

destroy:
	@echo "Deleting release $(RELEASE_NAME) from $(NAMESPACE)"
	kubectl delete -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT) || true
	kubectl delete namespace $(NAMESPACE) --context $(K8S_CONTEXT) || true

install: setup
	@echo "Installing release $(RELEASE_NAME) into namespace $(NAMESPACE)"
	helm template $(CHART_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(K8S_CONTEXT) \
		--version $(CHART_VERSION) \
		--values default_values.yaml > $(RELEASE_NAME).yaml
	kubectl create ns $(NAMESPACE) --context $(K8S_CONTEXT) || true
	kubectl apply -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT)

test:
	kubectl wait --namespace $(NAMESPACE) --context $(K8S_CONTEXT) --for=condition=ready pod \
		--selector=app.kubernetes.io/name=cert-manager --timeout=120s
	kubectl create ns tests --context $(K8S_CONTEXT) || true
	kubectl delete certificate selfsigned-cert -n tests || true
	kubectl apply -f test.yaml --context $(K8S_CONTEXT)
	sleep 10
	kubectl describe certificate -n tests
