#!/bin/bash

# We abort the script as soon as we hit an error (as soon as a command exits
# with a non-zero exit status)
set -e

# `cunnie-deployments` is the checked-out GitHub repo that contains our BOSH
# manifests and our directors' `-state.json` files
pushd cunnie-deployments

# We invoke the script that generates our BOSH director's manifest, e.g.
# `aws.sh`, `azure.sh`. The output, the BOSH director's manifest, is named
# `bosh-$IAAS.yml`, e.g. `bosh-aws.yml`
bin/$IAAS.sh

# Does ${DEPLOYMENTS_YML} have a complete set of interpolated variables?
# Abort if not (`--var-errs`).
bosh int bosh-$IAAS.yml \
  --var-errs \
  -l <(echo "$DEPLOYMENTS_YML") \
  -l <(curl https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml) \
  > /dev/null

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
if bosh create-env bosh-$IAAS.yml \
  -l <(echo "$DEPLOYMENTS_YML") \
  -l <(curl https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml); then
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

# We copy our repo with its new commit to a new directory, which will be used as
# an input to the subsequent job. Note that `cp -R` works as well as `rsync`; we
# use `rsync` out of force of habit.
rsync -avH cunnie-deployments/ cunnie-deployments-with-state/

# We exit with the return code of `bosh create-env`; if the deploy failed, then
# this Concourse task failed
exit $DEPLOY_EXIT_STATUS
