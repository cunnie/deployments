#!/bin/bash -ex
#
# usage:
#   bin/vsphere-perf.sh
#
# creates BOSH Directors to test performance of different stemcells
#
#
unset BOSH_DEPLOYMENT
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."
cd $DEPLOYMENTS_DIR

pushd $DEPLOYMENTS_DIR/../bosh-deployment; git pull -r; popd

set -- \
  vsphere-no-nsx 10.9.2.21 "/dev/null"            "/dev/null"  \
  vsphere-nsx    10.9.2.22 "etc/vsphere-nsx.yml"  "/dev/null"  \

while [ $# -gt 1 ]; do
  DIRECTOR_NAME=$1
  DIRECTOR_IP=$2
  OPTIONS_FILE_YML_1=$3
  OPTIONS_FILE_YML_2=$4

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
    -o etc/jumpbox_key.yml \
    -o etc/human-readable-names.yml \
    -o etc/perf.yml \
    \
    -v director_name=$DIRECTOR_NAME \
    -v internal_ip=$DIRECTOR_IP \
    -v stemcell=jammy \
    \
    -l <(lpass show --note deployments.yml) \
    -o $OPTIONS_FILE_YML_1 \
    -o $OPTIONS_FILE_YML_2 \
    \
    -v network_name=guest \
    -v vcenter_dc=dc \
    -v vcenter_cluster=cl \
    -v vcenter_rp=perf \
    -v vcenter_ds=SSD-1 \
    -v vcenter_ip=vcenter-80.nono.io \
    -v vcenter_user=a@vsphere.local \
    -v vcenter_templates=bosh-vsphere-templates \
    -v vcenter_vms=bosh-vsphere-vms \
    -v vcenter_disks=bosh-vsphere-disks \

  bosh alias-env $DIRECTOR_NAME -e $DIRECTOR_IP --ca-cert <(credhub get -n /bosh-vsphere/$DIRECTOR_NAME/director_ssl --key=ca)
  export BOSH_CLIENT=admin
  export BOSH_CLIENT_SECRET=$(lpass show --note deployments.yml | bosh int --path /admin_password -)
  bosh -e $DIRECTOR_NAME upload-stemcell --sha1 5677eba3f09d8a29833a10081eecd1a1598e9946 \
    https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-jammy-go_agent?v=1.105
  bosh -e $DIRECTOR_NAME update-cloud-config -n vsphere-perf/cloud-config.yml

  shift 4
done
