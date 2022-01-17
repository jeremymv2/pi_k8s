NAME          = "prometheus"
NAMESPACE     = "monitoring"
RELEASE_TAG   = "v0.10.0"
SRC_DIR       = kube-prometheus-0.10.0
MANIFEST      = $(SRC_DIR)/manifests/setup/namespace.yaml

include ../../../Makefile

$(MANIFEST):
	@echo "Fecthing release $(RELEASE_TAG)"
	@wget -q -O - "https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/$(RELEASE_TAG).tar.gz" | tar xz

upgrade: $(MANIFEST)
	@echo "Upgrading $(NAME)"
	@kubectl apply -n $(NAMESPACE) --context $(KUBE_CONTEXT) -f $(MANIFEST)
	@kubectl apply --server-side --context $(KUBE_CONTEXT) -f $(SRC_DIR)/manifests/setup
	@until kubectl get servicemonitors --all-namespaces --context $(KUBE_CONTEXT) ; do date; sleep 1; echo ""; done
	@kubectl apply --context $(KUBE_CONTEXT) -f $(SRC_DIR)/manifests/

apply: upgrade

uninstall:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	@kubectl delete --context $(KUBE_CONTEXT) \
		--wait=false \
		--ignore-not-found=true -f $(SRC_DIR)/manifests/ \
		-f $(SRC_DIR)/manifests/setup || true
	@rm -f ../../../installed/prometheus
