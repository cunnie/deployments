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
# bosh create-env bosh-aws.yml -l <(lpass show --note deployments.yml) -l <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml)
# bosh -e bosh-aws.nono.io alias-env aws
#
EOF

bosh interpolate ~/workspace/bosh-deployment/bosh.yml \
  -o ~/workspace/bosh-deployment/aws/cpi.yml \
  -o ~/workspace/bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -o etc/aws.yml \
  -o etc/nginx.yml \
  -o etc/ntp.yml \
  -o etc/pdns.yml \
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
  >> $DEPLOYMENTS_DIR/bosh-aws.yml
