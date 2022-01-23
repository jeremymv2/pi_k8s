include ../../../Makefile

NAME = flannel
NAMESPACE = kube-system
#EXTRA_OPTS = --dry-run=server
mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

upgrade:
	@echo "Upgrading $(NAME)"
	@for f in $(shell ls *yaml); do \
		../../../util/apply.sh $(current_dir)/$${f}; done

apply: upgrade

uninstall:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	@for f in $(shell ls -r *yaml); do cat $${f} | kubectl delete -n $(NAMESPACE) \
		--wait=false \
		--ignore-not-found=true \
		--context $(KUBE_CONTEXT) -f - || true; done
	@rm -f ../../../installed/flannel
