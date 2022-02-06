include ../../Makefile

NAME ?= flannel
NAMESPACE = kube-system
#EXTRA_OPTS = --dry-run=server
mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

export NAMESPACE

upgrade:
	@echo "Upgrading $(NAME)"
	@for f in $(shell ls $(NAME)/*.yaml); do \
		../../util/apply.sh $(current_dir)/$${f}; done
	@touch ../../installed/calico

apply: upgrade

uninstall:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	@for f in $(shell ls -r $(NAME)/*.yaml); do cat $${f} | kubectl delete -n $(NAMESPACE) \
		--wait=false \
		--ignore-not-found=true \
		--context $(KUBE_CONTEXT) -f - || true; done
	@rm -f ../../installed/$(NAME)
