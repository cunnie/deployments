#!/bin/bash
#
# usage:
#   bin/vsphere-ipv4.sh
#
# Deploys a BOSH IPv4 vSphere Server
#
# Normally I'd create a manifest and interpolate the important things, but
# using that scheme is becoming increasingly contorted & unnatural, so I'm
# throwing in the towel & deploying my BOSH director the "recommended" way.
#
# bosh -e bosh-vsphere-ipv4.nono.io alias-env ipv4
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
  \
  --state=$DEPLOYMENTS_DIR/bosh-vsphere-ipv4-state.json \
  \
  -l <(lpass show --note deployments.yml) \
  \
  -o etc/common.yml \
  -o etc/vsphere.yml \
  -o etc/TLS.yml \
  \
  --vars-store=bosh-vsphere-ipv4-creds.yml \
  --var-file=commercial_ca_crt=etc/COMODORSACertificationAuthority.crt \
  --var-file=nono_io_crt=etc/nono.io.crt \
  --var-file=private_key=<(bosh int --path /bosh_deployment_key <(lpass show --note deployments.yml)) \
  \
  -v director_name=bosh-vsphere-ipv4 \
  -v internal_cidr=10.0.9.0/24 \
  -v internal_gw=10.0.9.1 \
  -v internal_ip=10.0.9.151 \
  -v external_ip=10.0.9.151 \
  -v external_fqdn="bosh-vsphere-ipv4.nono.io" \
  \
  -v network_name="VM Network" \
  -v vcenter_dc=dc \
  -v vcenter_cluster=cl \
  -v vcenter_rp=BOSH-IPv4 \
  -v vcenter_ds=SSD-0 \
  -v vcenter_ip=vcenter.nono.io \
  -v vcenter_user=administrator@vsphere.local \
  -v vcenter_templates=bosh-vsphere-ipv4-templates \
  -v vcenter_vms=bosh-vsphere-ipv4-vms \
  -v vcenter_disks=bosh-vsphere-ipv4-disks
