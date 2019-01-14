#!/bin/bash
#
# usage:
#   bin/nginx-ntp-pdns.sh
#
# Deploy nginx + NTP + PowerDNS servers to AWS, Azure, and GCE
#
DEPLOYMENTS_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/.."

if ! lpass status; then
  echo "Log into LastPass!" >&2
  exit 1
fi

set -- \
  aws 52.0.56.137 52-0-56-137 t3.nano \
  azure 52.187.42.158 52-187-42-158 standard_b1s \

while [ $# -gt 0 ]; do
  IAAS=$1
  bosh \
    -e vsphere \
    -d nginx-ntp-pdns-$IAAS \
    deploy \
    $DEPLOYMENTS_DIR/nginx-ntp-pdns.yml \
    -l <(lpass show --note deployments.yml) \
    -l <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/conf/sslip.io%2Bnono.io.yml) \
    --no-redact \
    \
    -v iaas=$IAAS \
    -v external_ip=$2 \
    -v sslip_io_hostname=$3 \
    -v vm_type=$4 \

  shift 4
done
