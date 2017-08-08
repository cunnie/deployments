#
# usage:
#   bin/vsphere.sh
#
# Generate manifest for vSphere dual-homed server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR=$PWD

cat > $DEPLOYMENTS_DIR/bosh-vsphere.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-vsphere.yml -v vcenter_ip=vcenter.XXXXX -v vcenter_password=XXXX -l vsphere-creds.yml
# bosh -e 10.85.46.6 --ca-cert <(bosh int vsphere-creds.yml --path /director_ssl/ca) alias-env nsx-t
#
EOF

bosh interpolate ~/workspace/bosh-deployment/bosh.yml \
  -o ~/workspace/bosh-deployment/vsphere/cpi.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -o etc/vsphere.yml \
  --vars-store $DEPLOYMENTS_DIR/vsphere-creds.yml \
  -v vcenter_user=root \
  -v vcenter_dc=private \
  -v vcenter_cluster=private \
  -v vcenter_resource_pool=mouse \
  -v vcenter_ds=vnx5600-pizza-2 \
  -v vcenter_disks=delete-me \
  -v vcenter_vms=delete-me \
  -v vcenter_templates=delete-me \
  -v director_name=nsx-t \
  -v network_name=mouse \
  -v internal_ip=10.85.46.6 \
  -v internal_gw=10.85.46.1 \
  -v internal_cidr=10.85.46.0/24 \
  -v nats_password=SingGoddessTheAngerOfPeleus \
  -v director_name=nsx-t \
  >> $DEPLOYMENTS_DIR/bosh-vsphere.yml
