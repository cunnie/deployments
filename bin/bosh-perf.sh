#!/bin/bash
#
# usage:
#   bin/bosh-perf.sh
#
# creates BOSH Directors to test performance of different stemcells
#

# bosh create-env bosh-vsphere.yml -l <(lpass show --note deployments.yml) --vars-store=bosh-vsphere-creds.yml
# bosh -e bosh-vsphere.nono.io alias-env vsphere
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."
cd $DEPLOYMENTS_DIR

pushd $DEPLOYMENTS_DIR/../bosh-deployment; git pull -r; popd

set -- \
  xenial      10.9.2.11 "" \
  bionic      10.9.2.12 "-o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/use-bionic.yml"\
  jammy       10.9.2.13 "" \
  jammy-clang 10.9.2.14 "" \

MANIFEST_DIR=bosh-perf
mkdir -p $MANIFEST_DIR
while [ $# -gt 1 ]; do
  STEMCELL=$1
  DIRECTOR_IP=$2
  OPTIONS=$3
  mkdir -p $MANIFEST_DIR/$STEMCELL

  bosh interpolate -d $STEMCELL $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
    \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/cpi.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/misc/source-releases/bosh.yml \
    \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/resource-pool.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/bpm.yml \
    -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/enable-metrics.yml \
    $OPTIONS \
    \
    -o etc/common.yml \
    -o etc/human-readable-names.yml \
    \
    -v director_name=$STEMCELL \
    -v internal_cidr=10.9.2.0/23 \
    -v internal_gw=10.9.2.1 \
    -v internal_ip=$DIRECTOR_IP \
    \
    -v admin_password='((admin_password))' \
    -v blobstore_agent_password='((blobstore_agent_password))' \
    -v blobstore_director_password='((blobstore_director_password))' \
    -v credhub_admin_client_secret='((credhub_admin_client_secret))' \
    -v credhub_cli_password='((credhub_cli_password))' \
    -v credhub_cli_user_password='((credhub_cli_user_password))' \
    -v credhub_encryption_password='((credhub_encryption_password))' \
    -v hm_password='((hm_password))' \
    -v mbus_bootstrap_password='((mbus_bootstrap_password))' \
    -v nats_password='((nats_password))' \
    -v nats_sync_password='((nats_sync_password))' \
    -v postgres_password='((postgres_password))' \
    -v registry_password='((registry_password))' \
    -v uaa_admin_client_secret='((uaa_admin_client_secret))' \
    -v uaa_clients_director_to_credhub='((uaa_clients_director_to_credhub))' \
    -v uaa_encryption_key_1='((uaa_encryption_key_1))' \
    -v uaa_login_client_secret='((uaa_login_client_secret))' \
    \
    -v network_name=Guest \
    -v vcenter_dc=dc \
    -v vcenter_cluster=cl \
    -v vcenter_rp=BOSH-PERF \
    -v vcenter_ds=SSD-1 \
    -v vcenter_ip=vcenter-70.nono.io \
    -v vcenter_user=administrator@vsphere.local \
    -v vcenter_templates=bosh-vsphere-templates \
    -v vcenter_vms=bosh-vsphere-vms \
    -v vcenter_disks=bosh-vsphere-disks \
    \
    --vars-store=$MANIFEST_DIR/$STEMCELL/creds.yml \
    \
    > $MANIFEST_DIR/$STEMCELL/bosh.yml

  shift 3
done
