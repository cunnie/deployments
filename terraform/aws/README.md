### ns-aws.sslip.io

#### Create Infrastructure

```shell
cd sslip.io-infra/
terraform apply
terraform output > ../sslip.io-vm/infra.auto.tfvars
```

#### Create VM ns-aws

```shell
cd sslip.io-vm/
terraform apply
```

After `terraform apply`, follow the instructions
[here](https://github.com/cunnie/sslip.io/tree/main/etcd#configure-ns-awssslipio)
to finish customizing.
