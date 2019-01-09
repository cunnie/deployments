#!/bin/bash
#
# usage:
#   bin/vsphere.sh
#
# Deploys a BOSH vSphere Server
#
# Normally I'd create a manifest and interpolate the important things, but
# using that scheme is becoming increasingly contorted & unnatural, so I'm
# throwing in the towel & deploying my BOSH director the "recommended" way.
#
# bosh -e bosh-vsphere.nono.io alias-env vsphere
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

bosh create-env $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/cpi.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/resource-pool.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/bpm.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/blobstore-https.yml \
  \
  --state=$DEPLOYMENTS_DIR/bosh-vsphere-state.json \
  \
  -l <(lpass show --note deployments.yml) \
  \
  -o etc/common.yml \
  -o etc/vsphere.yml \
  -o etc/TLS.yml \
  \
  --vars-store=bosh-vsphere-creds.yml \
  --var-file=commercial_ca_crt=etc/COMODORSACertificationAuthority.crt \
  --var-file=nono_io_crt=etc/nono.io.crt \
  --var-file=private_key=<(bosh int --path /bosh_deployment_key <(lpass show --note deployments.yml)) \
  \
  -v director_name=bosh-vsphere \
  -v internal_cidr=10.2.0.0/24 \
  -v internal_gw=10.2.0.1 \
  -v internal_ip=10.2.0.250 \
  -v external_ip=73.189.219.4 \
  -v external_fqdn="bosh-vsphere.nono.io" \
  \
  -v default_key_name=bosh_deployment_no_ecdsa \
  -v default_security_groups=[bosh] \
  -v region=us-east-1 \
  \
  -v network_name=Guest \
  -v vcenter_dc=dc \
  -v vcenter_cluster=cl \
  -v vcenter_rp=BOSH \
  -v vcenter_ds=SSD-0 \
  -v vcenter_ip=vcenter-67.nono.io \
  -v vcenter_user=administrator@vsphere.local \
  -v vcenter_templates=bosh-vsphere-templates \
  -v vcenter_vms=bosh-vsphere-vms \
  -v vcenter_disks=bosh-vsphere-disks
