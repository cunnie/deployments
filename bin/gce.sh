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

echo "not ready yet: need to make this BOSH specific"

cat > $DEPLOYMENTS_DIR/bosh-gce.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh2 create-env bosh-gce.yml -l <(lpass show --note deployments) -l gce-creds.yml -l <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml)
# bosh2 -e bosh-gce.nono.io --ca-cert <(bosh int gce-creds.yml --path /director_ssl/ca) alias-env gce
#
EOF

bosh interpolate ~/workspace/bosh-deployment/bosh.yml \
  -o ~/workspace/bosh-deployment/gce/cpi.yml \
  -o ~/workspace/bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -o etc/gce.yml \
  -o etc/nginx.yml \
  -o etc/ntp.yml \
  -o etc/pdns.yml \
  --vars-store $DEPLOYMENTS_DIR/gce-creds.yml \
  -v access_key_id="((gce_access_key_id))" \
  -v secret_access_key="((gce_secret_access_key))" \
  -v region=us-east-1 \
  -v az=us-east-1a \
  -v default_key_name=gce_nono \
  -v default_security_groups=[bosh] \
  -v subnet_id=subnet-1c90ef6b \
  -v director_name=bosh-gce \
  -v internal_cidr=10.0.0.0/24 \
  -v internal_gw=10.0.0.1 \
  -v internal_ip=10.0.0.6 \
  -v external_ip=52.0.56.137 \
  -v admin_password="((admin_password))" \
  -v blobstore_agent_password="((blobstore_agent_password))" \
  -v blobstore_director_password="((blobstore_director_password))" \
  -v hm_password="((hm_password))" \
  -v mbus_bootstrap_password="((mbus_bootstrap_password))" \
  -v nats_password="((nats_password))" \
  -v postgres_password="((postgres_password))" \
  -v registry_password="((registry_password))" \
  -v private_key=$HOME/.ssh/gce_nono.pem \
  >> $DEPLOYMENTS_DIR/bosh-gce.yml
