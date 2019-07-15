#!/bin/bash
#
# usage:
#   bin/vsphere.sh
#
# Generate manifest for vSphere BOSH Director
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
# set up Let's Encrypt
export NSUPDATE_SERVER="ns-he.nono.io"
export NSUPDATE_KEY="$HOME/letsencrypt.key"
~/.acme.sh/acme.sh --issue \
  -d bosh-vsphere.nono.io \
  --dns dns_nsupdate

DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

pushd $DEPLOYMENTS_DIR/../bosh-deployment; git pull -r; popd

cat > $DEPLOYMENTS_DIR/bosh-vsphere.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-vsphere.yml -l <(lpass show --note deployments.yml) --vars-store=bosh-vsphere-creds.yml
# bosh -e bosh-vsphere.nono.io alias-env vsphere
#
EOF

bosh interpolate $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/cpi.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/vsphere/resource-pool.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/bpm.yml \
  \
  -o etc/common.yml \
  -o etc/multicpi.yml \
  -o etc/TLS.yml \
  \
  --vars-file <(printf '{"uaa_jwt_signing_key":{"private_key":"((uaa_jwt_signing_key.private_key))","public_key":"((uaa_jwt_signing_key.public_key))"}}') \
  --vars-store=bosh-vsphere-creds.yml \
  --var-file commercial_ca_crt=etc/trustid-x3-root.pem \
  --var-file nono_io_crt=etc/nono.io.crt \
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
  -v vcenter_rp=BOSH \
  -v vcenter_ds=NAS-0 \
  -v vcenter_ip=vcenter-67.nono.io \
  -v vcenter_user=administrator@vsphere.local \
  -v vcenter_templates=bosh-vsphere-templates \
  -v vcenter_vms=bosh-vsphere-vms \
  -v vcenter_disks=bosh-vsphere-disks \
  --var-file=nono_io_crt=$HOME/.acme.sh/bosh-vsphere.nono.io/fullchain.cer \
  \
  >> $DEPLOYMENTS_DIR/bosh-vsphere.yml
