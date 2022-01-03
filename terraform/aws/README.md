### ns-aws.sslip.io

After `terraform apply`, do the following to finish customizing:

```shell
ssh ns-aws.sslip.io
lpass login brian.cunnie@gmail.com
lpass show --note etcd-ca-key.pem | sudo tee -a /etc/etcd/ca-key.pem
lpass show --note etcd-key.pem | sudo tee /etc/etcd/etcd-key.pem
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl stop etcd
sudo systemctl start etcd
sudo journalctl -xefu # # look for any errors on startup
```
