#!/bin/bash
set -e

cd cunnie-deployments
bin/$IAAS.sh
bosh create-env bosh-$IAAS.yml \
  -l <(echo "$DEPLOYMENTS_YML") \
  -l <(curl https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml)

if ! git diff --quiet HEAD --; then
  git config --global user.name "Concourse CI"
  git config --global user.email brian.cunnie@gmail.com

  git add .
  git commit -m"Concourse CI automated BOSH deployer :airplane:"
fi
