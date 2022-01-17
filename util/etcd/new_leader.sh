#!/usr/bin/env bash

NEW_LEADER=${1:?leader member id required}
TARGET=${2:-controller0}

. endpoints.sh

ssh root@"${TARGET}" "${ETCDCTL}" \
	--endpoints="${ENDPOINTS}" \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
	--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
	move-leader "${NEW_LEADER}"
