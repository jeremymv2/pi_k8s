RELEASE_NAME  := velero
NAMESPACE  := velero
K8S_CONTEXT    := kubernetes-admin@pi-k8s
CHART_NAME := velero
CHART_REPO := vmware-tanzu
CHART_VERSION := 2.27.3
REPO_URL   := https://vmware-tanzu.github.io/helm-charts
VELERO_CLIENT_VERSION := v1.7.1
AWS_ACCESS_KEY_ID ?= key_id
AWS_SECRET_ACCESS_KEY ?= secret
BUCKET_PROVIDER := aws
BUCKET_PROVIDER_PLUGIN_TAG := v1.3.0
BUCKET_NAME := jmiller-velero
BACKUP_CONFIG_REGION := us-east-1
SNAPSHOT_CONFIG_REGION := us-east-1
SNAPSHOTS_ENABLED := true
DEPLOY_RESTIC := true
UPGRADE_CRDS := false
CREDENTIALS_FILE_PATH := /home/jmiller/.aws/credentials
VELERO_CLIENT = velero-client/velero

$(VELERO_CLIENT):
	mkdir velero-client
	curl -L \
 	  https://github.com/vmware-tanzu/velero/releases/download/$(VELERO_CLIENT_VERSION)/velero-$(VELERO_CLIENT_VERSION)-linux-amd64.tar.gz \
	  -o velero.tar.gz
	tar xvf velero.tar.gz -C velero-client --strip-components 1

setup: $(VELERO_CLIENT)
	helm repo add $(CHART_REPO) $(REPO_URL)

destroy:
	@echo "Deleting chart release $(RELEASE_NAME) with version $(VERSION) from \
		$(CHART_REPO)/$(CHART_NAME) into namespace $(NAMESPACE)"
	helm uninstall $(RELEASE_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(K8S_CONTEXT)
	kubectl delete namespace $(NAMESPACE) --context $(K8S_CONTEXT)

install: setup
	@echo "Installing chart release $(RELEASE_NAME) with version $(VERSION) from \
		$(CHART_REPO)/$(CHART_NAME) into namespace $(NAMESPACE)"
	helm install $(RELEASE_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(K8S_CONTEXT) \
		--version $(CHART_VERSION) \
		--create-namespace \
		--set-file credentials.secretContents.cloud=$(CREDENTIALS_FILE_PATH) \
		--set upgradeCRDs=$(UPGRADE_CRDS) \
		--set deployRestic=$(DEPLOY_RESTIC) \
		--set snapshotsEnabled=$(SNAPSHOTS_ENABLED) \
		--set configuration.provider=$(BUCKET_PROVIDER) \
		--set configuration.backupStorageLocation.name=$(BUCKET_PROVIDER) \
		--set configuration.backupStorageLocation.bucket=$(BUCKET_NAME) \
		--set configuration.backupStorageLocation.config.region=$(BACKUP_CONFIG_REGION) \
		--set configuration.volumeSnapshotLocation.name=$(BUCKET_PROVIDER) \
		--set configuration.volumeSnapshotLocation.config.region=$(SNAPSHOT_CONFIG_REGION) \
		--set initContainers[0].name=velero-plugin-for-$(BUCKET_PROVIDER) \
		--set initContainers[0].image=velero/velero-plugin-for-$(BUCKET_PROVIDER):$(BUCKET_PROVIDER_PLUGIN_TAG) \
		--set initContainers[0].volumeMounts[0].mountPath=/target \
		--set initContainers[0].volumeMounts[0].name=plugins
