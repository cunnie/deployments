#!/usr/bin/env bash

set -xue

START=$(date +%s)
SCRIPT_DIR=${BASH_SOURCE%/*}

for i in $(seq 1 65); do
    ITERATION_START=$(date +%s)
    (export BOSH_DEPLOYMENT=dummy1; bosh deploy -n $SCRIPT_DIR/dummy1.yml -v network=vsphere-subnet) &
    (export BOSH_DEPLOYMENT=dummy2; bosh deploy -n $SCRIPT_DIR/dummy2.yml -v network=vsphere-subnet) &
    wait
    if [ $(( $(date +%s) - ITERATION_START )) -gt "600" ]; then
        echo "Exiting; live deployment with unresponsive VM"
        exit 1
    fi
    (export BOSH_DEPLOYMENT=dummy1; bosh -n deld) &
    (export BOSH_DEPLOYMENT=dummy2; bosh -n deld) &
    wait
    echo "Iteration $i elapsed seconds: $(( $(date +%s) - ITERATION_START ))"
done

echo "TOTAL elapsed seconds: $(( $(date +%s) - START ))"
