#!/bin/bash
#
# usage:
#   bin/cf.sh
#
# Deploys Cloud Foundry
#
# set up Let's Encrypt
export NSUPDATE_SERVER="ns-he.nono.io"
export NSUPDATE_KEY="$HOME/letsencrypt.key"
~/.acme.sh/acme.sh --issue \
  -d *.cf.nono.io \
  -d foundry.fun \
  -d *.foundry.fun \
  -d diarizer.com \
  --dns dns_nsupdate \


DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."
export BOSH_ENVIRONMENT=vsphere

pushd $DEPLOYMENTS_DIR/../cf-deployment; git pull -r; popd

# Don't fill up Director's disk: delete old releases
#bosh clean-up --all

# We don't use the primary cloud config (we already have one); instead,
#   we set up a secondary config
bosh update-config \
  --non-interactive \
  --type cloud \
  --name cf \
  <(bosh int \
    -o $DEPLOYMENTS_DIR/cf/cloud-config-operations.yml \
    -l $DEPLOYMENTS_DIR/cf/cloud-config-vars.yml \
    $DEPLOYMENTS_DIR/../cf-deployment/iaas-support/vsphere/cloud-config.yml)

# We set up a runtime config that colocates BOSH DNS, but we customize
# it so it only includes it on the `cf` deployment, for BOSH DNS interferes
# with our other deployments which have custom DNS servers
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
  --fix \
  $DEPLOYMENTS_DIR/../cf-deployment/cf-deployment.yml \
  -l <(lpass show --note cf.yml) \
  -v system_domain=cf.nono.io \
  -v app_domain=foundry.fun \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/scale-to-one-az.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/use-haproxy.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/use-postgres.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/test/add-persistent-isolation-segment-diego-cell.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/windows2019-cell.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/use-latest-windows2019-stemcell.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/use-online-windows2019fs.yml \
  -o $DEPLOYMENTS_DIR/../cf-deployment/operations/experimental/use-jammy.yml \
  -o $DEPLOYMENTS_DIR/cf/letsencrypt.yml \
  -o $DEPLOYMENTS_DIR/cf/haproxy-on-ipv6.yml \
  -o $DEPLOYMENTS_DIR/cf/override-app-domain.yml \
  -o $DEPLOYMENTS_DIR/cf/diego-cells.yml \
  -v haproxy_private_ip=10.9.250.10 \
  --var-file=star_cf_nono_io_crt=$HOME/.acme.sh/\*.cf.nono.io/fullchain.cer \
  --var-file=star_cf_nono_io_key=$HOME/.acme.sh/\*.cf.nono.io/\*.cf.nono.io.key \

 # post-install setup
cf api api.cf.nono.io # or whatever your Cloud Foundry's API endpoint is
cf auth admin $(bosh int --path=/cf_admin_password <(lpass show --note cf.yml))
cf create-space -o system system # don't worry if it's already created
cf t -o system -s system
 # The following is needed for Docker-related CF Acceptance test to pass
cf enable-feature-flag diego_docker # necessary if you're running the Docker tests (`"include_docker": true`)
 # The following is needed for CredHub-related CF Acceptance test to pass
cf create-security-group credhub <(echo '[{"protocol":"tcp","destination":"10.0.0.0/8","ports":"8443,8844","description":"credhub"}]')
cf bind-running-security-group credhub
cf bind-staging-security-group credhub
