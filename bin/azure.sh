#!/bin/bash
#
# usage:
#   bin/azure.sh
#
# Generate manifest for Azure BOSH server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

cat > $DEPLOYMENTS_DIR/bosh-azure.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-azure.yml -l <(lpass show --note deployments.yml) -l <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml)
# bosh -e bosh-azure.nono.io alias-env azure
#
EOF

bosh interpolate $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/azure/cpi.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -o etc/azure.yml \
  -o etc/nginx.yml \
  -o etc/ntp.yml \
  -o etc/pdns.yml \
  --var-file nono_io_crt=etc/nono.io.crt \
  -v dns_recursor_ip="168.63.129.16" \
  -v internal_gw="10.0.0.1" \
  -v internal_cidr="10.0.0.0/24" \
  -v internal_ip="10.0.0.5" \
  -v external_ip="52.187.42.158" \
  -v director_name="azure" \
  -v vnet_name=boshnet \
  -v subnet_name=bosh \
  -v subscription_id=a1ac8d5a-7a97-4ed5-bfd1-d7822e19cae9 \
  -v tenant_id=682bd378-95db-41bd-8b1e-70fb407c4b10 \
  -v client_id=bf7f78c1-6924-4a02-965c-b66f481a9b5f \
  -v resource_group_name=bosh-res-group \
  -v storage_account_name=cunniestore \
  -v default_security_group=nsg-bosh \
  >> $DEPLOYMENTS_DIR/bosh-azure.yml
