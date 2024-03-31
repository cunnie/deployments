#!/bin/bash
#
# usage:
#   bin/bosh-perf.sh
#
# creates BOSH Directors to test performance of different stemcells
#
#
set -eux -o pipefail

unset BOSH_DEPLOYMENT
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."
cd $DEPLOYMENTS_DIR

pushd $DEPLOYMENTS_DIR/../bosh-deployment; git pull -r; popd

set -- \
  bosh-test.nono.io 10.9.16.21 jammy "" \


MANIFEST_DIR=bosh-perf
mkdir -p $MANIFEST_DIR
while [ $# -gt 1 ]; do
  DIRECTOR_FQDN=$1
  DIRECTOR_IP=$2
  STEMCELL=$3
  OPTIONS_YML=$4

  DIRECTOR_NAME=${DIRECTOR_FQDN%%.*} # basename $DIRECTOR_FQDN
  mkdir -p $MANIFEST_DIR/$STEMCELL

  bosh -nd $DIRECTOR_NAME deploy $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
    --no-redact \
    \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/cpi.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/misc/source-releases/bosh.yml \
    \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/resource-pool.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/misc/source-releases/uaa.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/misc/source-releases/credhub.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/bpm.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/misc/bosh-dev.yml \
    \
    -o <(echo -e "${OPTIONS_YML}") \
    \
    -o etc/jumpbox_key.yml \
    -o etc/human-readable-names.yml \
    -o etc/perf.yml \
    -o etc/fqdn.yml \
    \
    -v director_name=$DIRECTOR_NAME \
    -v director_fqdn=$DIRECTOR_FQDN \
    -v internal_ip=$DIRECTOR_IP \
    -v stemcell=$STEMCELL \
    \
    -l <(lpass show --note deployments.yml) \
    \
    -v network_name=guest \
    -v vcenter_dc=dc \
    -v vcenter_cluster=cl \
    -v vcenter_rp=perf \
    -v vcenter_ds=NAS-0 \
    -v vcenter_ip=vcenter-80.nono.io \
    -v vcenter_user=a@vsphere.local \
    -v vcenter_templates=bosh-vsphere-templates \
    -v vcenter_vms=bosh-vsphere-vms \
    -v vcenter_disks=bosh-vsphere-disks \

  bosh alias-env $DIRECTOR_NAME -e $DIRECTOR_FQDN --ca-cert <(credhub get -n /bosh-vsphere/$DIRECTOR_NAME/director_ssl --key=ca)
  export BOSH_CLIENT=admin
  export BOSH_CLIENT_SECRET=$(lpass show --note deployments.yml | bosh int --path /admin_password -)
  bosh -e $DIRECTOR_NAME upload-stemcell --sha1 f4fb29e2a62a44ad8c0d48fb5331d5189070ae27 \
  https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-jammy-go_agent?v=1.301
  bosh -e $DIRECTOR_NAME update-cloud-config -n bosh-perf/cloud-config.yml

  shift 4
done
