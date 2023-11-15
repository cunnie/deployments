### Terraform: Provision GKE Cluster

The Terraform templates were taken from the repo,
<https://github.com/hashicorp/learn-terraform-provision-gke-cluster>, a
companion repo to the [Provision a GKE Cluster (Google
Cloud)](https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster),
containing Terraform configuration files to provision an GKE cluster on GCP.

This repo also creates a VPC and subnet for the GKE cluster. This is not
required but highly recommended to keep your GKE cluster isolated.

### Ongoing Maintenance

```bash
gcloud auth application-default login # fixes "oauth2: cannot fetch token: 400 Bad Request"
terraform apply -refresh-only # get any k8s upgrades done from console
terraform init -upgrade # Get the latest GCP Terraform provider
gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output --raw region)
```

### [Creating the NGINX Ingress Controller on GKE](https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke)

_[We could've gone with the [gce](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) ingress controller, but it seemed to force us to use the more expensive "premium" load balancer tier, and we didn't want to spend extra $30/month]_

```bash
 # show values
helm show values ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
 # install
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  -f nginx-values.yml \
  --wait
```

Find the newly-assigned load balancer IP (this saves us $30/mo versus a
"Premium Tier" load balancer). In this example, it's 35.209.72.245:

```bash
 # find the external IP
kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller
```

### Update the DNS

- ci.nono.io
- gke.nono.io
- vault.nono.io

### [TLS (cert-manager)](https://cert-manager.io/docs/installation/kubernetes/)

#### 4. [Deploy an Example Service](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/#step-4---deploy-an-example-service)

Let's install the sample services to test the controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/deployment.yaml
# expected output: deployment.extensions "kuard" created

kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/service.yaml
# expected output: service "kuard" created
```

Let's download and edit the Ingress (I've already configured `gke.nono.io` to
point to the external IP at 35.209.72.245):

```bash
curl -o ingress-kuard.yml https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/ingress.yaml
sed -i "s/example.example.com/gke.nono.io/g" ingress-kuard.yml
kubectl apply -f ingress-kuard.yml
# expected output: ingress.networking.k8s.io/kuard created
```

Let's use curl to check (note the cert is still self-signed at this point):

```bash
curl -kivL -H 'Host: gke.nono.io' 'http://35.209.72.245'
```

#### 5. [Deploy cert-manager](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/#step-5---deploy-cert-manager)

We choose to install with `helm`:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --wait
```

Let's check that the 3 pods are up & running:

```bash
kubectl get pods --namespace cert-manager
```

#### 6. [Configure Let’s Encrypt Issuer](https://cert-manager.io/docs/tutorials/acme/ingress/#step-6-configure-let-s-encrypt-issuer)

Let's deploy the staging & production ClusterIssuers:

```bash
curl --fail -OL https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/staging-issuer.yaml
sed -i 's/user@example.com/brian.cunnie@gmail.com/;s/Issuer/ClusterIssuer/' staging-issuer.yaml
kubectl apply -f staging-issuer.yaml
# expected output: issuer.cert-manager.io "letsencrypt-staging" created
```

```bash
curl --fail -OL https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/production-issuer.yaml
sed -i 's/user@example.com/brian.cunnie@gmail.com/;s/Issuer/ClusterIssuer/' production-issuer.yaml
kubectl apply -f production-issuer.yaml
# expected output: issuer.cert-manager.io "letsencrypt-production" created
```

Check that the issuers have registered:

```bash
for issuer in staging prod; do
  kubectl describe clusterissuer letsencrypt-${issuer} | \
    grep "The ACME account was registered with the ACME server"
done
```

#### 7. [Deploy a TLS Ingress Resource](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/#step-7---deploy-a-tls-ingress-resource)

Let's deploy the ingress resource using annotations to obtain the certificate:

```bash
curl --fail -OL https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/ingress-tls.yaml
sed -i 's/example.example.com/gke.nono.io/' ingress-tls.yaml
sed -i 's~cert-manager.io/issuer~cert-manager.io/cluster-issuer~' ingress-tls.yaml
kubectl apply -f ingress-tls.yaml
```

Let's check the certificate again; verify the issuer is "Let's Encrypt":

```bash
curl -kivL https://gke.nono.io
```

Let's do the production certificate:

```bash
sed -i 's/letsencrypt-staging/letsencrypt-prod/' ingress-tls.yaml
kubectl apply -f ingress-tls.yaml
```

If desired, you can check the certificates:

```bash
kubectl get certificate # takes ~30s to become ready ("READY" == "True")
kubectl describe certificate quickstart-example-tls
kubectl describe secret quickstart-example-tls
```

And now browse: <https://gke.nono.io/>

### Install Concourse CI

These instructions are patterned after
<https://github.com/concourse/concourse-chart>.

```bash
kubectl apply -f concourse.yml # creates LoadBalancer on port 2222 for external worker
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm install ci concourse/concourse \
  -f concourse-values.yml \
  --set secrets.githubClientSecret=$(lpass show --note deployments.yml | yq e .github_concourse_nono_auth_client_secret -) \
  --set secrets.hostKey="$(lpass show --note deployments.yml | yq e .tsa_host_key.private_key -)" \
  --set secrets.hostKeyPub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrchtcCq6WFbl2xlWaKQP1UIUDUPPjKrndtrPXFArPs4+zOn5RcGf4zpO2GUD8fZl+8tikG7b+YQTfyOB08zeuA+WqpBVmiaXyK7OJhzuEWwqa60p5Ni1SyNRtcgntY8DLkKnWqzhDaVT/FcXIbnDfyMCDxp7Gs023jha3IGKeIIhRsOkJDcsfByxF63GP70WEs49JNToDCC3CIo8JEGXunjF1matILpJhupsa3obMOk2OCGNI9nleiRfSjE51f9hzYAa1wKqCoBbgOtVQ3mz59yxTFobVZFBP6fZX2GWXaLWHPPiAUtMhiL87pHsa43K0iiV6Yk59yoZ67mOdachp web@ci.nono.io" \
  --set secrets.workerKey="$(lpass show --note deployments.yml | yq e .worker_key.private_key -)" \
  --set secrets.workerKeyPub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0SIrGT+qIE7w8i67B/YDCfHINEU0LUP67SesaPaesq26rb/HHckPvBfRj+gCxKMvmTipUIVaQLBZlsPEMb+1V8xJBs2s4+9MU6QG6i7CEYTWyYlhVSDxU4HtwxGGnW9c5lASBB1jPkx2gWv0kgQYXQfrcbXSJ4fUtgdo0ZtePnXV7Qd30YUoR2fcuqEdAGg0S317V54vgeD2tfL04Qwhyu2Hbz4ZwTyhNe1YNcKET6v8ttRjVOIfMe+FF+JHqGJUiu5jygJ2p+29sm50JHEuxK+HjYpajmW8BRmXK7fIvDX24RDIs9ACZ+s+asEU8yEKkmdnFB5kUAukQWRuqUWYd worker@ci.nono.io" \
  --set secrets.sessionSigningKey="$(lpass show --note deployments.yml | yq e .session_signing_key.private_key -)" \
  --set secrets.vaultAuthParam="$(lpass show --note deployments.yml | yq e .vault_client_auth_param -)" \
  --wait
```

We need to find the load balancer's IP address. In this example it's 35.209.139.217:

```bash
kubectl get services -A
```

Now we need to update the property `instance_groups/name=worker/jobs/name=worker/properties/hosts` to the new IP address, e.g. `35.209.139.217:2222` in the [worker manifest](https://github.com/cunnie/deployments/blob/main/sslip.io.yml) and redeploy. Check that the worker has registered after deployment completes:

```bash
fly -t nono workers
```

Let's recreate our pipelines:

```bash
 # stemcells
fly -t nono sp -p stemcell -c <(curl -L https://raw.githubusercontent.com/cunnie/deployments/main/ci/pipeline-stemcell.yml) -l <(lpass show --note deployments.yml)
fly -t nono expose-pipeline -p stemcell
fly -t nono unpause-pipeline -p stemcell
 # vault test
fly -t nono sp -p ozymandias -c <(curl -L https://raw.githubusercontent.com/cunnie/deployments/main/ci/pipeline-ozymandias.yml) -l <(lpass show --note deployments.yml)
fly -t nono expose-pipeline -p ozymandias
fly -t nono unpause-pipeline -p ozymandias
 # badges
fly -t nono sp -p badges -c <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/main/ci/pipeline-badges.yml)
fly -t nono expose-pipeline -p badges
fly -t nono unpause-pipeline -p badges
 # sslip.io
fly -t nono sp -p sslip.io -c <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/main/ci/pipeline-sslip.io.yml)
fly -t nono expose-pipeline -p sslip.io
fly -t nono unpause-pipeline -p sslip.io
 # u2date
fly -t nono sp -p u2date -c <(curl -L https://raw.githubusercontent.com/cunnie/u2date/main/ci/pipeline.yml)
fly -t nono expose-pipeline -p u2date
fly -t nono unpause-pipeline -p u2date
```

### Installing Vault

From
<https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide?in=vault/kubernetes>:

```bash
kubectl create namespace vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault --versions
 # the following `--dry-run` will show the k8s deployments, services, etc.
helm install vault hashicorp/vault \
  --namespace vault \
  -f vault-values.yml \
  --dry-run
helm install vault hashicorp/vault \
  --namespace vault \
  -f vault-values.yml \
  --wait
helm status vault -n vault
helm get manifest vault -n vault
 # To propagate changes after modifying vault-values.yml
kubectl delete pod vault-0 -n vault
helm upgrade vault hashicorp/vault \
  --namespace vault \
  -f vault-values.yml \
  --wait
```

Then browse to <https://vault.nono.io> and unlock the vault.

```bash
curl \
  --request POST \
  --data '{"secret_shares": 1, "secret_threshold": 1}' \
  https://vault.nono.io/v1/sys/init | jq
```

Record `keys` and `root_token`.

```bash
export VAULT_TOKEN=hvs.FieEoSIxxxxxxxxxxxx
export VAULT_ADDR=https://vault.nono.io
curl \
    --request POST \
    --data '{"key": "5a302397xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}' \
    $VAULT_ADDR/v1/sys/unseal | jq
 # check initialization status
curl $VAULT_ADDR/v1/sys/init
```

FYI, to seal a vault:

```bash
curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    $VAULT_ADDR/v1/sys/seal
```

Create a key-value `concourse/` path in Vault for Concourse to access its
secrets:

```bash
vault secrets enable -version=1 -path=concourse kv
```

Create `concourse-policy.hcl` so that our Concourse server has access to that
path. Let's upload that policy to Vault:

```bash
vault policy write concourse concourse-policy.hcl
```

Let's enable the `approle` backend on Vault:

```bash
vault auth enable approle
```

Let's create the Concourse `approle`:

```bash
vault write auth/approle/role/concourse policies=concourse period=1h
```

We need the `approle`'s `role_id` and `secret_id` to set in our Concourse
server:

```bash
vault read auth/approle/role/concourse/role-id
  # role_id   045e3a37-6cc4-4f6b-xxxx-xxxxxxxxxxxx
vault write -f auth/approle/role/concourse/secret-id
  # secret_id 85ed8dec-757d-f6c2-xxxx-xxxxxxxxxxxx
```

Write our new secret to our `deployments.yml`; it should look something like the following:

```yaml
vault_client_auth_param: role_id:045e3a37-6cc4-4f6b-4312-36eed80f7adc\,secret_id:59b8015d-8d4a-fcce-f689-0cfa6a29f48c
```

Update our Concourse server with the new secret:

```bash
helm repo update
helm search repo concourse/concourse --versions # idle curiousity to see the latest version
helm upgrade ci concourse/concourse \
  -f concourse-values.yml \
  --set secrets.githubClientSecret=$(lpass show --note deployments.yml | yq e .github_concourse_nono_auth_client_secret -) \
  --set secrets.hostKey="$(lpass show --note deployments.yml | yq e .tsa_host_key.private_key -)" \
  --set secrets.hostKeyPub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrchtcCq6WFbl2xlWaKQP1UIUDUPPjKrndtrPXFArPs4+zOn5RcGf4zpO2GUD8fZl+8tikG7b+YQTfyOB08zeuA+WqpBVmiaXyK7OJhzuEWwqa60p5Ni1SyNRtcgntY8DLkKnWqzhDaVT/FcXIbnDfyMCDxp7Gs023jha3IGKeIIhRsOkJDcsfByxF63GP70WEs49JNToDCC3CIo8JEGXunjF1matILpJhupsa3obMOk2OCGNI9nleiRfSjE51f9hzYAa1wKqCoBbgOtVQ3mz59yxTFobVZFBP6fZX2GWXaLWHPPiAUtMhiL87pHsa43K0iiV6Yk59yoZ67mOdachp web@ci.nono.io" \
  --set secrets.workerKey="$(lpass show --note deployments.yml | yq e .worker_key.private_key -)" \
  --set secrets.workerKeyPub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0SIrGT+qIE7w8i67B/YDCfHINEU0LUP67SesaPaesq26rb/HHckPvBfRj+gCxKMvmTipUIVaQLBZlsPEMb+1V8xJBs2s4+9MU6QG6i7CEYTWyYlhVSDxU4HtwxGGnW9c5lASBB1jPkx2gWv0kgQYXQfrcbXSJ4fUtgdo0ZtePnXV7Qd30YUoR2fcuqEdAGg0S317V54vgeD2tfL04Qwhyu2Hbz4ZwTyhNe1YNcKET6v8ttRjVOIfMe+FF+JHqGJUiu5jygJ2p+29sm50JHEuxK+HjYpajmW8BRmXK7fIvDX24RDIs9ACZ+s+asEU8yEKkmdnFB5kUAukQWRuqUWYd worker@ci.nono.io" \
  --set secrets.sessionSigningKey="$(lpass show --note deployments.yml | yq e .worker_key.private_key -)" \
  --set secrets.vaultAuthParam="$(lpass show --note deployments.yml | yq e .vault_client_auth_param -)" \
  --wait
 # I'm not sure that I needed the following
kubectl rollout restart deployment/ci-web
```

Create a secret for our Concourse pipeline that tests Vault:

```bash
vault kv put -mount=concourse main/ozymandias-secret value="Look on my Works, ye Mighty, and despair\!"
vault kv put -mount=concourse main/docker_token value="deb9e84e-f36e-xxxx-xxxx-xxxxxxxxxxxx"
```

Change the default storage class to fix "had volume node affinity conflict"
error when scheduling pods:

```bash
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass standard-rwo -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
 # deploy, then create _another_ storage class & make it the default
kubectl get storageclasses.storage.k8s.io standard-rwo -o yaml | sed 's=standard-rwo=&-2=' | kubectl apply -f -
kubectl patch storageclass standard-rwo -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```
### Updating Concourse CI

```bash
helm repo update
helm search repo concourse/concourse --versions # idle curiousity to see the latest version
helm upgrade ci concourse/concourse \
  -f concourse-values.yml \
  --set secrets.githubClientSecret=$(lpass show --note deployments.yml | yq e .github_concourse_nono_auth_client_secret -) \
  --set secrets.hostKey="$(lpass show --note deployments.yml | yq e .tsa_host_key.private_key -)" \
  --set secrets.hostKeyPub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrchtcCq6WFbl2xlWaKQP1UIUDUPPjKrndtrPXFArPs4+zOn5RcGf4zpO2GUD8fZl+8tikG7b+YQTfyOB08zeuA+WqpBVmiaXyK7OJhzuEWwqa60p5Ni1SyNRtcgntY8DLkKnWqzhDaVT/FcXIbnDfyMCDxp7Gs023jha3IGKeIIhRsOkJDcsfByxF63GP70WEs49JNToDCC3CIo8JEGXunjF1matILpJhupsa3obMOk2OCGNI9nleiRfSjE51f9hzYAa1wKqCoBbgOtVQ3mz59yxTFobVZFBP6fZX2GWXaLWHPPiAUtMhiL87pHsa43K0iiV6Yk59yoZ67mOdachp web@ci.nono.io" \
  --set secrets.workerKey="$(lpass show --note deployments.yml | yq e .worker_key.private_key -)" \
  --set secrets.workerKeyPub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0SIrGT+qIE7w8i67B/YDCfHINEU0LUP67SesaPaesq26rb/HHckPvBfRj+gCxKMvmTipUIVaQLBZlsPEMb+1V8xJBs2s4+9MU6QG6i7CEYTWyYlhVSDxU4HtwxGGnW9c5lASBB1jPkx2gWv0kgQYXQfrcbXSJ4fUtgdo0ZtePnXV7Qd30YUoR2fcuqEdAGg0S317V54vgeD2tfL04Qwhyu2Hbz4ZwTyhNe1YNcKET6v8ttRjVOIfMe+FF+JHqGJUiu5jygJ2p+29sm50JHEuxK+HjYpajmW8BRmXK7fIvDX24RDIs9ACZ+s+asEU8yEKkmdnFB5kUAukQWRuqUWYd worker@ci.nono.io" \
  --set secrets.sessionSigningKey="$(lpass show --note deployments.yml | yq e .worker_key.private_key -)" \
  --set secrets.vaultAuthParam="$(lpass show --note deployments.yml | yq e .vault_client_auth_param -)" \
  --wait
kubectl rollout restart deployment/ci-web
```

### Backing Up Concourse CI

(Partially tested):

```bash
 # get the postgres user's password; the concourse user's is "concourse"
kubectl get secret ci-postgresql -o json \
  | jq -r '.data."postgresql-postgres-password"' \
  | base64 -d
kubectl exec -it ci-postgresql-0 -- bash
pg_dump -Fc -U concourse concourse > /tmp/concourse.dump # password is "concourse"
exit
  # after a recreate w/ pristine DB
kubectl cp ci-postgresql-0:/tmp/concourse.dump concourse.dump
kubectl exec -it ci-postgresql-0 -- bash
psql -U postgres concourse
  \dn; # only one schema, "public"
  drop schema public cascade;
  create schema public;
  grant usage on schema public to public;
  grant create on schema public to public;
  exit;
psql -U postgres concourse < /tmp/concourse.dump
```

#### Backing Up Vault

```shell
kubectl exec -it vault-0 -n vault -- cat /tmp/storageconfig.hcl # look for storage.path, i.e. "/vault/data"
 # We need to do this in two steps because Vault's tar is BusyBox's, not GNU's
kubectl exec -it -n vault vault-0 -- tar czf /tmp/vault_bkup.tgz /vault/data
 # I encode it in base64 to avoid "tar: Damaged tar archive"
kubectl exec -it -n vault vault-0 -- base64 /tmp/vault_bkup.tgz | base64 -d - > ~/Downloads/vault_bkup.tgz
```
