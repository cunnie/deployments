#!/bin/bash
set -e

pushd cunnie-deployments
bin/$IAAS.sh

if bosh create-env bosh-$IAAS.yml \
  -l <(echo "$DEPLOYMENTS_YML") \
  -l <(curl https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml); then
  GIT_COMMIT_MESSAGE="CI PASS: $IAAS BOSH deploy :airplane:"
else
  GIT_COMMIT_MESSAGE="CI FAIL: $IAAS BOSH deploy :airplane:"
fi

if ! git diff --quiet HEAD --; then
  git config --global user.name "Concourse CI"
  git config --global user.email brian.cunnie@gmail.com

  # check out branch because git-resource leaves us in `detached HEAD` state
  git checkout $DEPLOYMENTS_BRANCH
  git add .
  git commit -m"$GIT_COMMIT_MESSAGE"
fi
popd

rsync -avH cunnie-deployments/ cunnie-deployments-with-state/
