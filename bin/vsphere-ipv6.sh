#!/bin/bash

# bosh-ipv6.nono.io. == 2601:646:100:69f1::6
# bosh alias-env -e bosh-ipv6.nono.io ipv6

set -e
#  --var-errs \
#  --state=bosh-vsphere-ipv6-state.json \

DEPLOYMENTS_YML="$(lpass show --note deployments.yml)"

bosh create-env ~/workspace/bosh-deployment/bosh.yml \
  --vars-store=bosh-vsphere-ipv6-creds.yml \
  \
  -o ~/workspace/bosh-deployment/vsphere/cpi.yml \
  -o ~/workspace/bosh-deployment/vsphere/resource-pool.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -o ~/workspace/bosh-deployment/uaa.yml \
  -o ~/workspace/bosh-deployment/credhub.yml \
  -o ~/workspace/bosh-deployment/misc/ipv6/bosh.yml \
  -o ~/workspace/bosh-deployment/misc/ipv6/uaa.yml \
  -o ~/workspace/bosh-deployment/misc/ipv6/credhub.yml \
  -o ~/workspace/bosh-deployment/local-dns.yml \
  -v director_name=ipv6 \
  -v internal_cidr=2601:0646:0100:69f1:0000:0000:0000:0000/64 \
  -v internal_gw=2601:646:100:69f1:225:90ff:fef5:182b \
  -v internal_ip=2601:0646:0100:69f1:0000:0000:0000:0006 \
  -v network_name=IPv6 \
  -v vcenter_dc=dc \
  -v vcenter_cluster=cl \
  -v vcenter_rp=BOSH-IPv6 \
  -v vcenter_ds=FreeNAS \
  -v vcenter_ip=\"[2601:646:0100:69f0:0000:0000:0000:0105]\" \
  -v vcenter_user=administrator@vsphere.local \
  -v vcenter_password=$(bosh int --path=/vcenter_password <(echo "$DEPLOYMENTS_YML")) \
  -v vcenter_templates=bosh-ipv6-templates \
  -v vcenter_vms=bosh-ipv6-vms \
  -v vcenter_disks=bosh-ipv6-disks \
  \
  -v admin_password=$(bosh int --path=/admin_password <(echo "$DEPLOYMENTS_YML")) \
  -v blobstore_agent_password=$(bosh int --path=/blobstore_agent_password <(echo "$DEPLOYMENTS_YML")) \
  -v blobstore_director_password=$(bosh int --path=/blobstore_director_password <(echo "$DEPLOYMENTS_YML")) \
  -v hm_password=$(bosh int --path=/hm_password <(echo "$DEPLOYMENTS_YML")) \
  -v mbus_bootstrap_password=$(bosh int --path=/mbus_bootstrap_password <(echo "$DEPLOYMENTS_YML")) \
  -v nats_password=$(bosh int --path=/nats_password <(echo "$DEPLOYMENTS_YML")) \
  -v postgres_password=$(bosh int --path=/postgres_password <(echo "$DEPLOYMENTS_YML")) \
  -v registry_password=$(bosh int --path=/registry_password <(echo "$DEPLOYMENTS_YML"))
