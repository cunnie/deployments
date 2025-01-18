### worker.nono.io

#### Create GitHub Actions Worker VM

```bash
terraform init -upgrade
terraform apply -auto-approve -var='vsphere_password=xxxx'
```

Go to the console and install Fedora. "IPv6 privacy extensions" should be disabled.

Once it's up:

```bash
ssh -A runner.nono.io
echo runner.nono.io | sudo tee /etc/hostname
sudo dnf install -y git
git clone git@github.com:cunnie/bin.git
cd bin
./install_fedora.sh
sudo shutdown -r now
scp ~/.ssh/nono.pub runner.nono.io:~/.ssh/authorized_keys
ssh -A runner.nono.io
sudo visudo # passwordless sudo
```

