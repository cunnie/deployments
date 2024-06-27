### ns-aws.sslip.io

#### Create Infrastructure

```bash
cd sslip.io-infra/
terraform init -upgrade
terraform apply
terraform output > ../sslip.io-vm/infra.auto.tfvars
```

#### Create VM ns-aws

```bash
cd sslip.io-vm/
terraform apply
ssh ubuntu@ns-aws.nono.io
tail -f /var/log/cloud-init-output.log # takes ~6 minutes to finish
exit
ssh ns-aws # user cunnie
cd bin
./install_ns-aws.sh
```
