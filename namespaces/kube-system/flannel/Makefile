include ../../../Makefile

NAME ?= flannel
NAMESPACE = kube-system
#EXTRA_OPTS = --dry-run=server
mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

export NAMESPACE

install:
	@echo "Upgrading $(NAME)"
	envsubst < 01_flannel.yaml | kubectl apply --context $(KUBE_CONTEXT) -f -
	touch ../../../installed/flannel

apply: upgrade

uninstall:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	envsubst < 01_flannel.yaml | kubectl delete --context $(KUBE_CONTEXT) \
		--wait=false \
		--ignore-not-found=true \
		--context $(KUBE_CONTEXT) -f - || true
	rm -f ../../../installed/$(NAME)

destroy: uninstall
