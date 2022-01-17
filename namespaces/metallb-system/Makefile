include ../../Makefile

NAME = metallb
NAMESPACE = metallb-system
RELEASE_TAG = v0.11.0
mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

export RELEASE_TAG NAMESPACE

upgrade:
	@echo "Upgrading $(NAME)"
	@for f in $(shell ls *yaml); do \
		../../util/apply.sh $(current_dir)/$${f}; done

apply: upgrade

uninstall:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	@for f in $(shell ls -r *yaml); do cat $${f} | kubectl delete -n $(NAMESPACE) \
		--wait=false \
		--ignore-not-found=true \
		--context $(KUBE_CONTEXT) -f - || true; done
	@rm -f ../../installed/metallb
