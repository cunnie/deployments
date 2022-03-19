### Deploying ns-azure

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
ssh -A adminuser@20.212.40.63 # password is in terraform output
tail -f /var/log/cloud-init-output.log
```

#### Second run

```shell
ssh -A 20.212.40.63
bin/install_ns-azure.sh
```
