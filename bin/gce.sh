#!/bin/bash
#
# usage:
#   bin/gce.sh
#
# Generate manifest for GCE BOSH server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

cat > $DEPLOYMENTS_DIR/bosh-gce.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-gce.yml -l <(lpass show --note deployments.yml) --vars-store=bosh-gce-creds.yml
# bosh -e bosh-gce.nono.io alias-env gce
#
EOF

bosh interpolate $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/gcp/cpi.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/external-ip-not-recommended.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/external-ip-not-recommended-uaa.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/bpm.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/experimental/xenial-compiled-releases.yml \
  \
  -o etc/common.yml \
  -o etc/TLS.yml \
  -o etc/gce.yml \
  \
  --vars-store=bosh-gce-creds.yml \
  --var-file commercial_ca_crt=etc/COMODORSACertificationAuthority.crt \
  --var-file nono_io_crt=etc/nono.io.crt \
  -v dns_recursor_ip="169.254.169.254" \
  -v internal_gw="10.128.0.1" \
  -v internal_cidr="10.128.0.0/20" \
  -v internal_ip="10.128.0.2" \
  -v external_ip="104.154.39.128" \
  -v network="cf" \
  -v subnetwork="cf-e6ecf3fd8a498fbe" \
  -v tags="[ cf-internal, cf-bosh, cf-bosh-cli ]" \
  -v zone="us-central1-b" \
  -v project_id="blabbertabber" \
  -v director_name="gce" \
  -v external_fqdn="bosh-gce.nono.io" \
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
  >> $DEPLOYMENTS_DIR/bosh-gce.yml
