#!/usr/bin/env bash

set -xue

START=$(date +%s)
SCRIPT_DIR=${BASH_SOURCE%/*}

for i in $(seq 1 10); do
    ITERATION_START=$(date +%s)
    (export BOSH_DEPLOYMENT=dummy1; bosh deploy -n $SCRIPT_DIR/dummy1.yml; bosh -n deld) &
    (export BOSH_DEPLOYMENT=dummy2; bosh deploy -n $SCRIPT_DIR/dummy2.yml; bosh -n deld) &
    wait
    echo "Iteration $i elapsed seconds: $(( $(date +%s) - ITERATION_START ))"
done

echo "TOTAL elapsed seconds: $(( $(date +%s) - START ))"
