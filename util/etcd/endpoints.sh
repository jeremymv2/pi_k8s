#!/usr/bin/env bash

ETCDCTL="ETCDCTL_API=3 etcdctl"
PORT=2379

HOST_1=controller0
HOST_2=controller1
HOST_3=controller2

ENDPOINTS="$HOST_1:$PORT,$HOST_2:$PORT,$HOST_3:$PORT"
