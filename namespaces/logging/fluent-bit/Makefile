include ../../../Makefile

NAME = fluent-bit
NAMESPACE = logging
RELEASE_TAG = 1.8.11
FLUENT_ELASTICSEARCH_HOST = 192.168.1.201
FLUENT_ELASTICSEARCH_PORT = 9200
#EXTRA_OPTS = --dry-run=server
mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

export RELEASE_TAG NAMESPACE FLUENT_ELASTICSEARCH_HOST FLUENT_ELASTICSEARCH_PORT EXTRA_OPTS

apply:
	@echo "Upgrading $(NAME)"
	for f in $(shell ls *yaml); do \
		../../../util/apply.sh $(current_dir)/$${f}; done
	touch ../../../installed/fluentbit

destroy:
	@echo "Uninstalling $(NAME) from the $(NAMESPACE) namespace";
	for f in $(shell ls -r *yaml); do cat $${f} | kubectl delete -n $(NAMESPACE) \
		--wait=false \
		--ignore-not-found=true \
		--context $(KUBE_CONTEXT) -f - || true; done
	rm -f ../../../installed/fluentbit
