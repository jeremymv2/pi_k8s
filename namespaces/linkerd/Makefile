CHART_VERSION := 2.11.1
K8S_CONTEXT := kubernetes-admin@pi-k8s
CHART_NAME := linkerd2
NAMESPACE  := linkerd
CHART_REPO := linkerd
RELEASE_NAME := $(CHART_NAME)-$(shell echo $(CHART_VERSION) | sed -e 's/\./\-/g')
REPO_URL := https://helm.linkerd.io/stable
CERTS := issuer.key issuer.crt

cli:
	@echo "Installing linkerd cli"
	curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

setup: cli
	helm repo add $(CHART_NAME) https://helm.linkerd.io/stable
	helm repo update

viz:
	kubectl apply --context $(K8S_CONTEXT) -f viz.yaml

$(CERTS):
	step-cli certificate create root.linkerd.cluster.local ca.crt ca.key \
		--profile root-ca --no-password --insecure \
		--not-after=87600h
	step-cli certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
		--profile intermediate-ca --not-after 87600h --no-password --insecure \
		--ca ca.crt --ca-key ca.key

destroy:
	@echo "Deleting release $(RELEASE_NAME) from $(NAMESPACE)"
	kubectl -n $(NAMESPACE) delete -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT) || true
	kubectl delete -f viz.yaml --context $(K8S_CONTEXT) || true
	kubectl delete -f test_inject.yaml --context $(K8S_CONTEXT) || true
	kubectl delete -f test.yaml --context $(K8S_CONTEXT) || true
	kubectl -n $(NAMESPACE) delete -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT) || true
	kubectl delete namespace $(NAMESPACE) --context $(K8S_CONTEXT) || true
	kubectl delete namespace linkerd-viz --context $(K8S_CONTEXT) || true

install: setup $(CERTS)
	@echo "Installing release $(RELEASE_NAME) into namespace $(NAMESPACE)"
	kubectl create ns $(NAMESPACE) --context $(K8S_CONTEXT) || true
	helm template $(CHART_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(K8S_CONTEXT) \
		--version $(CHART_VERSION) \
  		--set-file identityTrustAnchorsPEM=ca.crt \
  		--set-file identity.issuer.tls.crtPEM=issuer.crt \
  		--set-file identity.issuer.tls.keyPEM=issuer.key \
		--set identity.issuer.crtExpiry=$$(date -d '+87600 hour' +"%Y-%m-%dT%H:%M:%SZ") \
		--values default_values.yaml > $(RELEASE_NAME).yaml
	kubectl -n $(NAMESPACE) apply -f $(RELEASE_NAME).yaml --context $(K8S_CONTEXT)

test:
	kubectl create ns tests --context $(K8S_CONTEXT) || true
	kubectl -n tests apply -f test.yaml --context $(K8S_CONTEXT)
	kubectl -n tests apply -f test_inject.yaml --context $(K8S_CONTEXT)
	sleep 10
	linkerd check
