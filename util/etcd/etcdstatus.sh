#!/usr/bin/env bash

TARGET=${1:-controller0}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${SCRIPT_DIR}/endpoints.sh

ssh root@"${TARGET}" "${ETCDCTL}" --write-out=table \
	--endpoints="${ENDPOINTS}" \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
	--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
	member list

ssh root@"${TARGET}" "${ETCDCTL}" --write-out=table \
	--endpoints="${ENDPOINTS}" \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
	--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
        endpoint status

ssh root@"${TARGET}" "${ETCDCTL}" --write-out=table \
	--endpoints="${ENDPOINTS}" \
	--cacert=/etc/kubernetes/pki/etcd/ca.crt \
	--cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
	--key=/etc/kubernetes/pki/apiserver-etcd-client.key \
        endpoint health
