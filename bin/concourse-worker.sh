#!/bin/bash
#
# usage:
#   bin/concourse-worker.sh
#
# Deploys a Concourse Worker
#
set -eu

DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

pushd $DEPLOYMENTS_DIR/../concourse-bosh-deployment/cluster
  git pull -r
  bosh \
    -e ipv4 deploy \
    -d concourse-worker \
    external-worker.yml \
    --no-redact \
    -l ../versions.yml \
    -v external_worker_network_name=guest \
    -v worker_vm_type=concourse-workers \
    -v instances=1 \
    -v azs=[z1] \
    -v deployment_name=concourse-worker \
    -v tsa_host=ci.nono.io \
    -v worker_tags=[] \
    -l <(lpass show --note deployments.yml)
popd
