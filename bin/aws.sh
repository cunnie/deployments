DEPLOYMENTS_DIR=~/workspace/deployments/
bosh interpolate ~/workspace/bosh-deployment/bosh.yml \
  -o ~/workspace/bosh-deployment/aws/cpi.yml \
  -o ~/workspace/bosh-deployment/external-ip-with-registry-not-recommended.yml \
  -o etc/aws.yml \
  --vars-store $DEPLOYMENTS_DIR/aws-creds.yml \
  -v access_key_id="((aws_access_key_id))" \
  -v secret_access_key="((aws_secret_access_key))" \
  -v region=us-east-1 \
  -v az=us-east-1b \
  -v default_key_name=aws_nono \
  -v default_security_groups=[bosh] \
  -v subnet_id=subnet-1c90ef6b \
  -v director_name=bosh-aws \
  -v internal_cidr=10.0.0.0/24 \
  -v internal_gw=10.0.0.1 \
  -v internal_ip=10.0.0.6 \
  -v external_ip=52.70.98.70 \
  -v admin_password="((admin_password))" \
  -v blobstore_agent_password="((blobstore_agent_password))" \
  -v blobstore_director_password="((blobstore_director_password))" \
  -v hm_password="((hm_password))" \
  -v mbus_bootstrap_password="((mbus_bootstrap_password))" \
  -v nats_password="((nats_password))" \
  -v postgres_password="((postgres_password))" \
  -v registry_password="((registry_password))" \
  -v private_key=../../.ssh/aws_nono.pem \
  --var-file certificate=nono.io.crt \
  > /tmp/bosh-aws.yml.$$
  cat - /tmp/bosh-aws.yml.$$ > $DEPLOYMENTS_DIR/bosh-aws.yml <<EOF
# bosh create-env bosh-aws.yml -l <(lpass show --note deployments)
# bosh -e bosh-aws.nono.io --ca-cert <(bosh int aws-creds.yml --path /director_ssl/ca) alias-env aws
EOF
