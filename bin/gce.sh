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
# bosh create-env bosh-gce.yml -l <(lpass show --note deployments.yml)
# bosh -e bosh-gce.nono.io alias-env gce
#
EOF

bosh interpolate $DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/misc/powerdns.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/gcp/cpi.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/external-ip-not-recommended.yml \
  -o $DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -o etc/gce.yml \
  --var-file nono_io_crt=etc/nono.io.crt \
  -v dns_recursor_ip="169.254.169.254" \
  -v internal_gw="10.128.0.1" \
  -v internal_cidr="10.128.0.0/20" \
  -v internal_ip="10.128.0.2" \
  -v external_ip="104.154.39.128" \
  -v network="cf" \
  -v subnetwork="cf-e6ecf3fd8a498fbe" \
  -v tags="[ cf-internal, cf-bosh ]" \
  -v zone="us-central1-b" \
  -v project_id="blabbertabber" \
  -v director_name="gce" \
  >> $DEPLOYMENTS_DIR/bosh-gce.yml
