include ../../Makefile

CHART_VERSION := 4.0.17
CHART_NAME := ingress-nginx
NAMESPACE  := $(CHART_NAME)
CHART_REPO := $(CHART_NAME)
RELEASE_NAME := $(CHART_NAME)-$(shell echo $(CHART_VERSION) | sed -e 's/\./\-/g')
REPO_URL := https://kubernetes.github.io/$(CHART_NAME)

setup: $(CMCTL)
	@echo "Adding helm repo"
	helm repo add $(CHART_REPO) $(REPO_URL)
	helm repo update

destroy:
	@echo "Deleting release $(RELEASE_NAME) from $(NAMESPACE)"
	kubectl -n $(NAMESPACE) delete -f $(RELEASE_NAME).yaml --context $(KUBE_CONTEXT) || true
	kubectl delete namespace $(NAMESPACE) --context $(KUBE_CONTEXT) || true
	rm -f ../../installed/ingress_nginx

apply: setup
	@echo "Installing release $(RELEASE_NAME) into namespace $(NAMESPACE)"
	helm template $(CHART_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(KUBE_CONTEXT) \
		--version $(CHART_VERSION) \
		--values default_values.yaml > $(RELEASE_NAME).yaml
	kubectl create ns $(NAMESPACE) --context $(KUBE_CONTEXT) || true
	kubectl -n $(NAMESPACE) apply -f $(RELEASE_NAME).yaml --context $(KUBE_CONTEXT)
	touch ../../installed/ingress_nginx

test:
	kubectl create ns tests --context $(KUBE_CONTEXT) || true
	kubectl -n tests apply -f ./test-simple-tls-svc.yaml --context $(KUBE_CONTEXT)
	sleep 10
	curl -s demo.k8s.ethzero.cloud | grep -q "It works"
