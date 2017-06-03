#
# usage:
#   bin/gce.sh
#
# Generate manifest for GCE BOSH server
#
# creds.yml has mostly valid certs, but decoy keys, so I can check
# it into a public repo without fear.
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR=~/workspace/deployments/

cat > $DEPLOYMENTS_DIR/bosh-gce.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh2 create-env bosh-gce.yml -l <(lpass show --note deployments)
# bosh2 -e bosh-gce.nono.io alias-env gce
#
EOF

bosh2 interpolate ~/workspace/bosh-deployment/bosh.yml \
  -o ~/workspace/bosh-deployment/powerdns.yml \
  -o ~/workspace/bosh-deployment/gcp/cpi.yml \
  -o ~/workspace/bosh-deployment/external-ip-not-recommended.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -o etc/gce.yml \
  --vars-store $DEPLOYMENTS_DIR/gce-creds.yml \
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
  -v admin_password="((admin_password))" \
  -v blobstore_agent_password="((blobstore_agent_password))" \
  -v blobstore_director_password="((blobstore_director_password))" \
  -v hm_password="((hm_password))" \
  -v mbus_bootstrap_password="((mbus_bootstrap_password))" \
  -v nats_password="((nats_password))" \
  -v postgres_password="((postgres_password))" \
  >> $DEPLOYMENTS_DIR/bosh-gce.yml
