#!/usr/bin/env bash

set -x

for link in $(ip link show | grep veth | awk '{print $2}' | awk -F@ '{print $1}'); do
  echo "Deleting $link"
  sudo ip link del "$link"
done
