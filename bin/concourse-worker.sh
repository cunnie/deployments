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
    int \
    -d concourse-worker \
    external-worker.yml \
    -l ../versions.yml \
    -v external_worker_network_name=vsphere-guest \
    -v worker_vm_type=concourse-workers \
    -v instances=1 \
    -v azs=[vsphere] \
    -v deployment_name=concourse-worker \
    -v tsa_host=ci.nono.io \
    -v worker_tags=[] \
    > $DEPLOYMENTS_DIR/concourse-worker.yml
popd
