#!/bin/bash
#
# usage:
#   bin/concourse.sh
#
# Generate manifest for Concourse/NTP/nginx/DNS server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

cat > $DEPLOYMENTS_DIR/concourse.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh -e gce deploy -d concourse concourse-ntp-pdns-gce.yml -l <(lpass show --note deployments.yml) -l <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml)  --no-redact
#
EOF

bosh int $DEPLOYMENTS_DIR/../concourse-deployment/lite/concourse.yml \
  -l $DEPLOYMENTS_DIR/../concourse-deployment/versions.yml \
  -o etc/concourse.yml \
  -o $DEPLOYMENTS_DIR/../concourse-deployment/cluster/operations/static-web.yml \
  -o $DEPLOYMENTS_DIR/../concourse-deployment/cluster/operations/github-auth.yml \
  -o $DEPLOYMENTS_DIR/../concourse-deployment/cluster/operations/privileged-https.yml \
  -o $DEPLOYMENTS_DIR/../concourse-deployment/cluster/operations/tls.yml \
  \
  --var-file atc_tls.certificate=etc/nono.io.crt \
  --var      atc_tls.private_key="((nono_io_key))" \
  \
  --var web_ip=104.155.144.4 \
  --var external_url=https://ci.nono.io \
  --var network_name=concourse \
  --var web_vm_type=concourse \
  --var db_vm_type=concourse \
  --var db_persistent_disk_type=db \
  --var worker_vm_type=concourse \
  --var deployment_name=concourse \
  --var postgres_password="((concourse_postgres_passwd))" \
  \
  --var github_client="{ username: d4d77ce34ecc620d5220, password: ((github_concourse_nono_auth_client_secret)) }" \
  --var github_auth.authorize="[ { organization: blabbertabber, teams: all } ]" \
  \
  >> $DEPLOYMENTS_DIR/concourse.yml
