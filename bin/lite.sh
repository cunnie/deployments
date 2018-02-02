#!/bin/bash
#
# usage:
#   bin/lite.sh
#
# Generate manifest for lite BOSH server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
# Don't save the state file in this repo, for we may have several BOSH Lite
# deployments spanning several VMs
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

cat > $DEPLOYMENTS_DIR/bosh-lite.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-lite.yml -l <(lpass show --note deployments.yml) --vars-store=bosh-lite-creds.yml --state=\$HOME/.bosh/bosh-lite-state.json
# bosh -e bosh-lite.nono.io alias-env lite
#
EOF

bosh interpolate $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/virtualbox/cpi.yml \
  -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
  -o ~/workspace/bosh-deployment/bosh-lite.yml \
  -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
  \
  -o etc/common.yml \
  -o etc/TLS.yml \
  \
  --vars-store=bosh-lite-creds.yml \
  --var-file commercial_ca_crt=etc/COMODORSACertificationAuthority.crt \
  --var-file nono_io_crt=etc/nono.io.crt \
  -v internal_gw=192.168.50.1 \
  -v internal_cidr=192.168.50.0/24 \
  -v internal_ip=192.168.50.6 \
  -v external_ip=192.168.50.6 \
  -v outbound_network_name=NatNetwork \
  -v director_name=lite \
  -v external_fqdn=bosh-lite.nono.io \
  \
  -v admin_password='((admin_password))' \
  -v blobstore_agent_password='((blobstore_agent_password))' \
  -v blobstore_director_password='((blobstore_director_password))' \
  -v credhub_admin_client_secret='((credhub_admin_client_secret))' \
  -v credhub_cli_password='((credhub_cli_password))' \
  -v credhub_encryption_password='((credhub_encryption_password))' \
  -v hm_password='((hm_password))' \
  -v mbus_bootstrap_password='((mbus_bootstrap_password))' \
  -v nats_password='((nats_password))' \
  -v postgres_password='((postgres_password))' \
  -v registry_password='((registry_password))' \
  -v uaa_admin_client_secret='((uaa_admin_client_secret))' \
  -v uaa_clients_director_to_credhub='((uaa_clients_director_to_credhub))' \
  -v uaa_login_client_secret='((uaa_login_client_secret))' \
  \
  >> $DEPLOYMENTS_DIR/bosh-lite.yml
