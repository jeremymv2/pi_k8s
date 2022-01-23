#!/usr/bin/env bash

set -x

function repo_owner_project() {
  git config --get remote.origin.url | awk -F: '{print $2}' | sed -e "s/\.git//" | \
   awk -F/ '{print $(NF-1)"/"$NF}'
}

export COMMIT_SHA GITHUB_SHA_URL

COMMIT_SHA="$(git log -n 1 --all --pretty=format:%H -- "$1")"
GITHUB_SHA_URL="https://github.com/$(repo_owner_project)/commit/$COMMIT_SHA"

envsubst < "$1" | kubectl apply $EXTRA_OPTS -n "$NAMESPACE" --context "$KUBE_CONTEXT" -f -
