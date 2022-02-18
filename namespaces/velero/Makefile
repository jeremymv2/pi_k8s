include ../../Makefile

KUBE_CONTEXT ?= kubernetes-admin@pi-k8s
RELEASE_NAME  := velero
NAMESPACE  := velero
CHART_NAME := velero
CHART_REPO := vmware-tanzu
CHART_VERSION := 2.27.3
REPO_URL   := https://vmware-tanzu.github.io/helm-charts
VELERO_CLIENT_VERSION := v1.7.1
VELERO_CLIENT_ARCH := linux-amd64
AWS_ACCESS_KEY_ID ?= key_id
AWS_SECRET_ACCESS_KEY ?= secret
BUCKET_PROVIDER := aws
BUCKET_PROVIDER_PLUGIN_TAG := v1.3.0
BUCKET_NAME := velero
#BACKUP_REGION := us-east-1
SNAPSHOT_REGION := us-east-1
## For Minio
BACKUP_REGION := minio
S3_FORCE_PATH_STYLE := true
S3_URL := http://192.168.1.201:9199
##
SNAPSHOTS_ENABLED := false
USE_RESTIC := true
UPGRADE_CRDS := false
DEFAULT_RESTIC_FOR_ALL := true
CREDENTIALS_FILE_PATH := ./credentials
VELERO_CLIENT = velero-client/velero

$(VELERO_CLIENT):
	mkdir velero-client
	curl -L \
 	  https://github.com/vmware-tanzu/velero/releases/download/$(VELERO_CLIENT_VERSION)/velero-$(VELERO_CLIENT_VERSION)-$(VELERO_CLIENT_ARCH).tar.gz \
	  -o velero.tar.gz
	tar xvf velero.tar.gz -C velero-client --strip-components 1

setup: $(VELERO_CLIENT)
	helm repo add $(CHART_REPO) $(REPO_URL)
	helm repo update

destroy:
	@echo "Deleting chart release $(RELEASE_NAME) with version $(VERSION) from \
		$(CHART_REPO)/$(CHART_NAME) into namespace $(NAMESPACE)"
	helm uninstall $(RELEASE_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(KUBE_CONTEXT)
	kubectl delete namespace $(NAMESPACE) --context $(KUBE_CONTEXT)



install: setup
	@echo "Installing chart release $(RELEASE_NAME) with version $(VERSION) from \
		$(CHART_REPO)/$(CHART_NAME) into namespace $(NAMESPACE)"
	helm install $(RELEASE_NAME) $(CHART_REPO)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--kube-context $(KUBE_CONTEXT) \
		--version $(CHART_VERSION) \
		--create-namespace \
		--set-file credentials.secretContents.cloud=$(CREDENTIALS_FILE_PATH) \
		--set defaultVolumesToRestic=$(DEFAULT_RESTIC_FOR_ALL) \
		--set upgradeCRDs=$(UPGRADE_CRDS) \
		--set deployRestic=$(USE_RESTIC) \
		--set snapshotsEnabled=$(SNAPSHOTS_ENABLED) \
		--set configuration.volumeSnapshotLocation.name=$(BUCKET_PROVIDER) \
		--set configuration.volumeSnapshotLocation.config.region=$(SNAPSHOT_REGION) \
		--set configuration.provider=$(BUCKET_PROVIDER) \
		--set configuration.backupStorageLocation.name=$(BUCKET_PROVIDER) \
		--set configuration.backupStorageLocation.bucket=$(BUCKET_NAME) \
		--set configuration.backupStorageLocation.config.region=$(BACKUP_REGION) \
		--set configuration.backupStorageLocation.config.s3ForcePathStyle=$(S3_FORCE_PATH_STYLE) \
		--set configuration.backupStorageLocation.config.s3Url=$(S3_URL) \
		--set initContainers[0].name=velero-plugin-for-$(BUCKET_PROVIDER) \
		--set initContainers[0].image=velero/velero-plugin-for-$(BUCKET_PROVIDER):$(BUCKET_PROVIDER_PLUGIN_TAG) \
		--set initContainers[0].volumeMounts[0].mountPath=/target \
		--set initContainers[0].volumeMounts[0].name=plugins
