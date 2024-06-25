### ns-azure.sslip.io

#### Create Infrastructure

```shell
cd sslip.io-infra/
terraform init -upgrade
terraform apply
terraform output > ../sslip.io-vm/infra.auto.tfvars
```

#### Create VM ns-azure

```shell
terraform apply -auto-approve -var="admin_password=Aa1_$(dd if=/dev/random bs=1 count=6 | base64)"
# to destroy:
# terraform apply -destroy -auto-approve -var=admin_password=Admin\!23
```

Note: it typically takes 234 seconds (~4 minutes) for the `install_ns-azure.sh`
cloud-init script to run after the VM has been created.

#### (Optional) check on the newly-created VM

ssh onto the newly created VM, check on the output

```shell
ssh -A adminuser@52.187.42.158 # password is in terraform output
tail -f /var/log/cloud-init-output.log
```

#### Second run

```shell
ssh -A 52.187.42.158
bin/install_ns-azure.sh
```

After `terraform apply`, follow the instructions
[here](https://github.com/cunnie/sslip.io/tree/main/etcd#configure-ns-azuresslipio)
to finish customizing.

### Notes

`install_ns-azure.sh` is a symbolic link; the file to which it's linked should
have the contents of
<https://raw.githubusercontent.com/cunnie/bin/main/install_ns-azure.sh>.

#### Why Didn't I go for IPv6?

I couldn't get it to work without upgrading from Basic to Standard SKU
(`CannotSpecifyBasicSkuPublicIpForIpV6NicIpConfiguration`). Upgrading SKUs was
a one-way process, so I could never rollback to Basic SKU if I ran into
trouble. And I couldn't mix SKUs, either
(`DifferentSkuLoadBalancersAndPublicIPAddressNotAllowed`).

It appears that if I upgrade to Standard, it requires a Standard Load Balancer,
which costs
[$18/month](https://azure.microsoft.com/en-us/pricing/details/load-balancer/),
which is more than I pay for my current instance.
