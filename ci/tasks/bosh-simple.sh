#!/bin/bash

# THIS IS A SIMPLIFIED SCRIPT FOR DEPLOYING A BOSH DIRECTOR
# It does not customize the passwords nor the SSL certificates

# We abort the script as soon as we hit an error (as soon as a command exits
# with a non-zero exit status)
set -e

# CUNNIE_DEPLOYMENTS_DIR is the root directory of the checked-out repo of
# `cunnie-deployments`; it contains our BOSH manifests and our directors'
# `-state.json` files; it also contains this script (task script) and task
# definition.
CUNNIE_DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."
pushd $CUNNIE_DEPLOYMENTS_DIR

# We attempt to deploy our BOSH director. We prepare a git commit message
# regardless whether our attempt succeeds or fails because we need to retain any
# change to the BOSH director's `-state.json` file. This is necessary in cases
# where a deploy proceeds far enough to create a broken director VM, for
# subsequent deploys must be able to destroy the broken director VM in order to
# free up its IP address so that the current deploy will succeed. The crucial
# information needed to destroy the  broken director VM is its VM's ID, which is
# recorded in the `-state.json` file.

# Note that `set -e` does not trigger an abort if the command that returns a
# non-zero exit code is the subject of an `if` block, i.e. `if bosh create-env`;
# this gives us the breathing room to commit our results regardless of whether
# `bosh create-env` succeeded or failed
if bosh create-env $CUNNIE_DEPLOYMENTS_DIR/../bosh-deployment/bosh.yml \
  -o $CUNNIE_DEPLOYMENTS_DIR/../bosh-deployment/misc/powerdns.yml \
  -o $CUNNIE_DEPLOYMENTS_DIR/../bosh-deployment/gcp/cpi.yml \
  -o $CUNNIE_DEPLOYMENTS_DIR/../bosh-deployment/external-ip-not-recommended.yml \
  -o $CUNNIE_DEPLOYMENTS_DIR/../bosh-deployment/jumpbox-user.yml \
  -l <(echo "$DEPLOYMENTS_YML") \
  --vars-store=simple-creds.yml \
  -v dns_recursor_ip="169.254.169.254" \
  -v internal_gw="10.128.0.1" \
  -v internal_cidr="10.128.0.0/20" \
  -v internal_ip="10.128.0.20" \
  -v external_ip="35.202.16.114" \
  -v network="cf" \
  -v subnetwork="cf-e6ecf3fd8a498fbe" \
  -v tags="[ cf-internal, cf-bosh, cf-bosh-cli ]" \
  -v zone="us-central1-b" \
  -v project_id="blabbertabber" \
  -v director_name="gce"
then
  GIT_COMMIT_MESSAGE="CI PASS: $IAAS BOSH deploy :airplane:"
  DEPLOY_EXIT_STATUS=0
else
  GIT_COMMIT_MESSAGE="CI FAIL: $IAAS BOSH deploy :airplane:"
  DEPLOY_EXIT_STATUS=1
fi

# Do we need to commit anything? If a new director hasn't been deployed (most
# often because there's been no change to the manifest, releases, or stemcell),
# then we don't need to commit
if ! git diff --quiet HEAD --; then
  # If we're in this block, then there has been a deployment. Let's set our
  # git author to avoid git's `*** Please tell me who you are.` error.
  git config --global user.name "Concourse CI"
  git config --global user.email brian.cunnie@gmail.com

  # We check out our branch's HEAD because Concourse's git-resource leaves us
  # in `detached HEAD` state. ${DEPLOYMENTS_BRANCH} is typically set to
  # `master`, but may be set to something else (usually while testing).
  git checkout $DEPLOYMENTS_BRANCH
  git add .
  git commit -m"$GIT_COMMIT_MESSAGE"
fi
popd

# We copy our repo with its new commit to a new directory. The Concourse job,
# after it finishes running this task, will push the new commit to GitHub.
# Note that `cp -R` works as well as `rsync`; we use `rsync` by force of
# habit.
rsync -aH cunnie-deployments/ cunnie-deployments-with-state/

# We exit with the return code of `bosh create-env`; if the deploy failed, then
# this Concourse task failed
exit $DEPLOY_EXIT_STATUS
