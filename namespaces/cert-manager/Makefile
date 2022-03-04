include ../../Makefile

CHART_VERSION := v1.7.1
CHART_NAME := cert-manager
NAMESPACE  := $(CHART_NAME)
CHART_REPO := jetstack
RELEASE_NAME := $(CHART_NAME)-$(shell echo $(CHART_VERSION) | sed -e 's/\./\-/g')
REPO_URL := https://charts.jetstack.io
CMCTL = cmctl.tar.gz
CLOUDFLARE_API_TOKEN = $(shell cat cloudflare_token)
EMAIL = jeremymv2@gmail.com

export EMAIL CLOUDFLARE_API_TOKEN

token:
	@echo $(CLOUDFLARE_API_TOKEN)

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

uninstall: destroy

destroy:
	@echo "Deleting release $(RELEASE_NAME) from $(NAMESPACE)"
	kubectl delete -f $(RELEASE_NAME).yaml --context $(KUBE_CONTEXT) || true
	kubectl delete namespace $(NAMESPACE) --context $(KUBE_CONTEXT) || true
	rm -f ../../installed/certmanager

selfsignedissuer:
	kubectl apply -f self-signed-issuer.yaml --context $(KUBE_CONTEXT)

apply: setup
	@echo "Installing release $(RELEASE_NAME) into namespace $(NAMESPACE)"
	helm template $(CHART_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(KUBE_CONTEXT) \
		--version $(CHART_VERSION) \
		--values default_values.yaml > $(RELEASE_NAME).yaml
	kubectl create ns $(NAMESPACE) --context $(KUBE_CONTEXT) || true
	kubectl apply -f $(RELEASE_NAME).yaml --context $(KUBE_CONTEXT)
	kubectl wait --namespace $(NAMESPACE) --context $(KUBE_CONTEXT) --for=condition=complete job \
		--selector=app.kubernetes.io/component=startupapicheck --timeout=180s
	envsubst < ./letsencryt-cloudflare-issuer.yaml | kubectl apply \
		--context $(KUBE_CONTEXT) -f -
	touch ../../installed/certmanager

test:
	kubectl create ns tests --context $(KUBE_CONTEXT) || true
	kubectl delete certificate test-ethzero-cloud -n tests || true
	kubectl apply -f ./test-issuer.yaml --context $(KUBE_CONTEXT)
	sleep 10
	kubectl describe certificate -n tests
