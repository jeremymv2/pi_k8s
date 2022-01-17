NAME          = metallb
NAMESPACE     = metallb-system
RELEASE_TAG   = v0.11.0

export RELEASE_TAG

include ../../Makefile

upgrade:
	@echo "Upgrading $(NAME)"
	@for f in $(shell ls *yaml); do envsubst < "$${f}" | kubectl apply -n $(NAMESPACE) \
		--context $(KUBE_CONTEXT) -f - ; done

apply: upgrade

uninstall:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	@for f in $(shell ls -r *yaml); do envsubst < "$${f}" | kubectl delete -n $(NAMESPACE) \
		--ignore-not-found=true \
		--context $(KUBE_CONTEXT) -f - || true; done
