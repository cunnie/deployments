#!/bin/bash
#
# usage:
#   bin/aws.sh
#
# Generate manifest for AWS BOSH/NTP/nginx/DNS server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

cat > $DEPLOYMENTS_DIR/bosh-aws.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-aws.yml -l <(lpass show --note deployments.yml) -l <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml) --vars-store=creds.yml
# bosh -e bosh-aws.nono.io alias-env aws
#
EOF

bosh interpolate $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/aws/cpi.yml \
  \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/local-dns.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/uaa.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/credhub.yml \
  \
  -o etc/aws.yml \
  -o etc/common.yml \
  -o etc/nginx.yml \
  -o etc/ntp.yml \
  -o etc/pdns.yml \
  \
  --vars-store=bosh-aws-creds.yml \
  --var-file nono_io_crt=etc/nono.io.crt \
  -v region=us-east-1 \
  -v az=us-east-1a \
  -v default_key_name=bosh_deployment_no_ecdsa \
  -v default_security_groups=[bosh] \
  -v subnet_id=subnet-1c90ef6b \
  -v director_name=bosh-aws \
  -v internal_cidr=10.0.0.0/24 \
  -v internal_gw=10.0.0.1 \
  -v internal_ip=10.0.0.6 \
  -v external_ip=52.0.56.137 \
  -v private_key="((bosh_deployment_key_no_ecdsa))" \
  \
  -v admin_password='((admin_password))' \
  -v blobstore_agent_password='((blobstore_agent_password))' \
  -v blobstore_director_password='((blobstore_director_password))' \
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
  >> $DEPLOYMENTS_DIR/bosh-aws.yml
