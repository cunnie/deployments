### worker.nono.io

#### Create GitHub Actions Worker VM

```bash
terraform init -upgrade
terraform apply -auto-approve -var='vsphere_password=xxxx'
```

Go to the console and install Fedora.

Once it's up:

```bash
ssh -A worker.nono.io
sudo dnf install -y git
git clone git@github.com:cunnie/bin.git
cd bin
./install_fedora.sh
```

