#!/usr/bin/env bash

ENDPOINT=${1:?specify endpoint to send request to}
REMOVE_ID=${2:?node member id required}
TARGET=${3:-controller0}

. endpoints.sh

ssh root@"${TARGET}" "${ETCDCTL}" \
	--endpoints "${ENDPOINT}" \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
	--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
	member remove "${REMOVE_ID}"
