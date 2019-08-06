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
  -d *.cf.nono.io \
  --dns dns_nsupdate

DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."
export BOSH_ENVIRONMENT=vsphere

pushd $DEPLOYMENTS_DIR/../cf-deployment; git pull -r; popd

# We don't use the primary config; instead we set a bunch of variables
bosh update-config \
  --non-interactive \
  --type cloud \
  --name cf \
  <(bosh int \
    -o $DEPLOYMENTS_DIR/cf/cloud-config-operations.yml \
    -l $DEPLOYMENTS_DIR/cf/cloud-config-vars.yml \
    $DEPLOYMENTS_DIR/../cf-deployment/iaas-support/vsphere/cloud-config.yml)

bosh update-config \
  --non-interactive \
  --type runtime \
  --name dns \
  -o $DEPLOYMENTS_DIR/cf/dns-on-cf-only.yml \
  $DEPLOYMENTS_DIR/../bosh-deployment/runtime-configs/dns.yml

bosh \
  -e vsphere \
  -d cf \
  deploy \
  --no-redact \
  $DEPLOYMENTS_DIR/../cf-deployment/cf-deployment.yml \
  -l <(lpass show --note cf.yml) \
  -v system_domain=cf.nono.io \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/scale-to-one-az.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/use-haproxy.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/use-latest-stemcell.yml \
  -o $DEPLOYMENTS_DIR/cf/letsencrypt.yml \
  -o $DEPLOYMENTS_DIR/cf/haproxy-on-ipv6.yml \
  -v haproxy_private_ip=10.0.250.10 \
  --var-file=star_cf_nono_io_crt=$HOME/.acme.sh/\*.cf.nono.io/fullchain.cer \
  --var-file=star_cf_nono_io_key=$HOME/.acme.sh/\*.cf.nono.io/\*.cf.nono.io.key \

