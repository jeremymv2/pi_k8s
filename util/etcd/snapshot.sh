#!/usr/bin/env bash

TARGET=${1:-controller0}

. endpoints.sh

ssh root@"${TARGET}" "${ETCDCTL}" --write-out=table \
	--endpoints="${TARGET}:${PORT}" \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
	--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
        snapshot save "snapshot_$(date +%F).db"
