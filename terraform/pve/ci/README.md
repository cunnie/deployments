# ci.nono.io

A continuous integration / continuous deployment (CI/CD).

## Pre-requisites

Set up Hashicorp Vault integration, though we're using the
open source alternative, OpenBao:

```bash
export VAULT_ADDR="https://vault.nono.io"
bao login # paste root token hvs.xxxxxxxxxxxxxxxxxxxxxxx
bao secrets enable -version=1 -path=concourse kv
  # Let's set a secret for a subsequent pipeline
bao kv put concourse/main/vault-secret value="I ❤️ CI"
```

Create `/tmp/concourse-policy.hcl`:

```json
path "concourse/*" {
  policy = "read"
}
```

Let's upload it to Vault:

```bash
bao policy write concourse /tmp/concourse-policy.hcl
```

Let's enable the `approle` backend on Vault:

```bash
bao auth enable approle
```

Create the Concourse `approle`

```bash
bao write auth/approle/role/concourse policies=concourse period=1h
```

We need the approle’s `role_id` and `secret_id` to set in our Concourse server:

```bash
bao read auth/approle/role/concourse/role-id
  # role_id    d218ef3a-1dda-e7c5-e123-c5524a1be79c
bao write -f auth/approle/role/concourse/secret-id
  # secret_id  1aac7167-1db0-fcdd-a79b-xxxxxxxxxxxx # check the GDoc
```

## Deploying Concourse

```bash
export TF_VAR_password=xxxxx
cd ci/
terraform init
terraform plan
terraform apply
```

Wait 5 minutes before logging in to make sure cloud-init has finished:

```bash
ssh ci.nono.io
```

Put in our secrets and start our server:

```bash
sudo nvim /etc/systemd/system/concourse-web.service
  # update CONCOURSE_GITHUB_CLIENT_SECRET CONCOURSE_VAULT_AUTH_PARAM
sudo systemctl daemon-reload && sudo systemctl start concourse-web
```

Browse <https://ci.nono.io>

- Download & install the fly executable

```bash
chmod +x fly
mv fly /opt/homebrew/bin
fly -t nono login --concourse-url=https://nono.nono.io
```

If you get the error, "Apple could not verify “fly” is free of malware that may harm your Mac..."
then Go to System Settings > Privacy & Security.
Find the security section and locate the blocked app.
Click "Open Anyway" and confirm your choice.
You may need to enter your password.

Let's set a quick pipeline to check Vault integration:

```bash
fly -t nono set-pipeline     -p vault -c etc/vault.yaml
fly -t nono unpause-pipeline -p vault
```
