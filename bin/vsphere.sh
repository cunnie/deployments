
# usage:
#   bin/vsphere.sh
#
# Generate manifest for vSphere dual-stack (IPv4 & IPv6) server
#
# --var-errs: don't use; it flags the variables I'll interpolate the _next_ stage
#
DEPLOYMENTS_DIR=$PWD

cat > $DEPLOYMENTS_DIR/bosh-vsphere.yml <<EOF
# DON'T EDIT; THIS FILE IS AUTO-GENERATED
#
# bosh create-env bosh-vsphere.yml -l <(lpass show --note deployments.yml)
#
# bosh -e bosh-vsphere.nono.io vsphere
#
EOF

bosh interpolate ~/workspace/bosh-deployment/bosh.yml \
  -o ~/workspace/bosh-deployment/vsphere/cpi.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -o ~/workspace/bosh-deployment/misc/ipv6/bosh.yml \
  -o etc/vsphere.yml \
  --var-file nono_io_crt=etc/nono.io.crt \
  -v vcenter_ip=vcenter.nono.io \
  -v vcenter_user=administrator@vsphere.local \
  -v vcenter_dc=dc \
  -v vcenter_cluster=cl \
  -v vcenter_ds=SSD \
  -v vcenter_disks=bosh-disks \
  -v vcenter_vms=bosh-vms \
  -v vcenter_templates=bosh-templates \
  -v director_name=vsphere \
  -v network_name="VM Network" \
  -v internal_ip=2601:646:102:95::106 \
  -v internal_gw=2601:646:102:95:82ea:96ff:fee7:5524 \
  -v internal_cidr=2601:646:102:95::/64 \
  -v director_name=vsphere \
  >> $DEPLOYMENTS_DIR/bosh-vsphere.yml
