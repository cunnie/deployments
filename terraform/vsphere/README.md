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
sudo lvextend -l +100%FREE /dev/mapper/fedora-root
sudo xfs_growfs /dev/mapper/fedora-root
sudo useradd -N -G docker runner
sudo su - runner
```

Follow the instructions in the [GitHub Actions Runner](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners) documentation to register the runner.

After rebooting, do the following to start the runner:

```bash
sudo tee /etc/systemd/system/github-runner.service << 'EOF'
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=/home/runner/actions-runner
ExecStart=/home/runner/actions-runner/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable github-runner
sudo systemctl start github-runner
```
