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

JAMMY_CLANG_YML='
- type: replace
  path: /releases/name=bosh
  value:
    name: bosh
    url: file:///home/cunnie/tmp/director-clang.tgz
    version: latest
'

set -- \
  xenial      xenial 10.9.2.21 "" \
  bionic      bionic 10.9.2.22 "" \
  jammy       jammy  10.9.2.23 "" \
  jammy-clang jammy  10.9.2.24 "${JAMMY_CLANG_YML}" \


MANIFEST_DIR=bosh-perf
mkdir -p $MANIFEST_DIR
while [ $# -gt 1 ]; do
  DIRECTOR_NAME=$1
  STEMCELL=$2
  DIRECTOR_IP=$3
  OPTIONS_YML=$4

  # cat <(echo -e "${OPTIONS_YML}")
  # exit

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
    -o etc/bosh-perf.yml \
    \
    -v director_name=$DIRECTOR_NAME \
    -v internal_ip=$DIRECTOR_IP \
    -v stemcell=$STEMCELL \
    \
    -l <(lpass show --note deployments.yml) \
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

  bosh alias-env $DIRECTOR_NAME -e $DIRECTOR_IP --ca-cert <(credhub get -n /bosh-vsphere/$DIRECTOR_NAME/director_ssl --key=ca)
  bosh -e $DIRECTOR_NAME upload-stemcell --sha1 c27cbd9ddba5df3163adb3066bfbdccdc7ef4941 \
    https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-jammy-go_agent?v=1.30
  bosh -e $DIRECTOR_NAME update-cloud-config -n bosh-perf/cloud-config.yml

  shift 4
done
