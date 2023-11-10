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
"Premium Tier" load balancer). In this example, it's 35.209.139.217:

```bash
kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller
```

### Update the DNS

- ci.nono.io
- gke.nono.io
- vault.nono.io

<!--
Setting up the load balancer is as simple as `kubectl apply`. I have customized:

```bash
kubectl apply -f nginx-ingress-controller.yml
```
Check the installed version
```bash
POD_NAMESPACE=ingress-nginx
POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -n ingress-nginx -- /nginx-ingress-controller --version # --help is useful, too
```
-->

### [TLS (cert-manager)](https://cert-manager.io/docs/installation/kubernetes/)

We choose to install with `helm`:
```bash
helm repo add jetstack https://charts.jetstack.io
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --wait
```

(I did not seem to run into the GKE `permission denied` error that they warn
about). Let's check that the 3 pods are up & running:

```bash
kubectl get pods --namespace cert-manager
```

<!--
Now let's create an issuer to test the webhook:
```bash
cat <<EOF > test-resources.yaml
```
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  dnsNames:
    - example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
```
```
EOF
```

And now let's apply those resources:
```bash
kubectl apply -f test-resources.yaml
kubectl describe certificate -n cert-manager-test
kubectl delete -f test-resources.yaml
```


#### 4. [Deploy an Example Service](https://cert-manager.io/docs/tutorials/acme/ingress/#step-4-deploy-an-example-service)

Let's install the sample services to test the controller:
```bash
kubectl apply -f https://netlify.cert-manager.io/docs/tutorials/acme/example/deployment.yaml
kubectl apply -f https://netlify.cert-manager.io/docs/tutorials/acme/example/service.yaml
```

Let's download and edit the Ingress (I've already configured `gke.nono.io` to
point to the GCP/GKE load balancer at 104.155.144.4):
```bash
curl -o ingress-kuard.yml -L https://netlify.cert-manager.io/docs/tutorials/acme/example/ingress.yaml
sed -i '' "s/example.example.com/gke.nono.io/g" ingress-kuard.yml
kubectl apply -f ingress-kuard.yml
```

Let's use curl to check (note the cert is still self-signed at this point):
```bash
curl -kivL -H 'Host: gke.nono.io' 'http://104.155.144.4'
```

-->

#### 6. [Configure Let’s Encrypt Issuer](https://cert-manager.io/docs/tutorials/acme/ingress/#step-6-configure-let-s-encrypt-issuer)

_[Inspired from <https://cert-manager.io/docs/tutorials/getting-started-with-cert-manager-on-google-kubernetes-engine-using-lets-encrypt-for-ingress-ssl/>]_

Let's deploy the staging & production issuers:

```bash
kubectl apply -f lets-encrypt.yml
kubectl describe clusterissuers.cert-manager.io letsencrypt-staging
kubectl describe clusterissuers.cert-manager.io letsencrypt-production
```

Chicken-and-egg hack to jumpstart issuing:

```
kubectl apply -f secret.yml
```

Let's use the production issuer:

```
kubectl annotate ingress web-ingress cert-manager.io/issuer=letsencrypt-production --overwrite
```

#### 7. [Step 7 - Deploy a TLS Ingress Resource](https://cert-manager.io/docs/tutorials/acme/ingress/#step-7-deploy-a-tls-ingress-resource)

Let's deploy the ingress resource using annotations to obtain the certificate:
```bash
kubectl apply -f <(
  curl -o- https://cert-manager.io/docs/tutorials/acme/example/ingress-tls.yaml |
  sed 's/example.example.com/gke.nono.io/')
kubectl get certificate # takes ~30s to become ready ("READY" == "True")
kubectl describe certificate quickstart-example-tls
kubectl describe secret quickstart-example-tls
```

Browse to <https://gke.nono.io> and notice that although the cert is still
invalid it's no longer self-signed; instead, it's issued by the Let's Encrypt
staging CA.

Let's do the production certificate:

```bash
kubectl apply -f <(
  curl -o- https://cert-manager.io/docs/tutorials/acme/example/ingress-tls-final.yaml |
  sed 's/example.example.com/gke.nono.io/')
kubectl delete secret quickstart-example-tls # triggers the process to get a new certificate
kubectl get certificate # takes ~30s to become ready ("READY" == "True")
kubectl describe certificate quickstart-example-tls
kubectl describe secret quickstart-example-tls
```

And now browse: <https://gke.nono.io/>

### Install sslip.io

```bash
kubectl apply -f <(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/master/k8s/sslip.io.yml)
```

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

### Install etcd

Create the k8s secret, `etcd-peer-tls`, with the etcd cluster's CA cert and TLS cert & key
```bash
kubectl create secret generic etcd-peer-tls \
  --from-file=ca.pem=<(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/main/etcd/ca.pem) \
  --from-file=etcd.pem=<(curl -L https://raw.githubusercontent.com/cunnie/sslip.io/main/etcd/etcd.pem) \
  --from-file=etcd-key.pem=<(lpass show --note etcd-key.pem)
```

```
kubectl apply -f k-v.io.yml
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

### Installing Vault

(Not tested)

From
<https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide?in=vault/kubernetes>

Create the namespace & deploy the TLS issuers to that namespace:
```bash
kubectl create namespace vault
kubectl apply -f <(
  curl -o- https://cert-manager.io/docs/tutorials/acme/example/staging-issuer.yaml |
  sed 's/user@example.com/brian.cunnie@gmail.com/') -n vault
kubectl apply -f <(
  curl -o- https://cert-manager.io/docs/tutorials/acme/example/production-issuer.yaml |
  sed 's/user@example.com/brian.cunnie@gmail.com/') -n vault
```

```bash
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
export VAULT_TOKEN=s.QmByxxxxxxxxxxxxxxxxxxxx
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
  # role_id    045e3a37-6cc4-4f6b-xxxx-xxxxxxxxxxxx
vault write -f auth/approle/role/concourse/secret-id
  # secret_id             85ed8dec-757d-f6c2-xxxx-xxxxxxxxxxxx
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

#### Backing Up Vault

```shell
kubectl exec -it vault-0 -n vault -- cat /tmp/storageconfig.hcl # look for storage.path, i.e. "/vault/data"
 # We need to do this in two steps because Vault's tar is BusyBox's, not GNU's
kubectl exec -it -n vault vault-0 -- tar czf /tmp/vault_bkup.tgz /vault/data
 # I encode it in base64 to avoid "tar: Damaged tar archive"
kubectl exec -it -n vault vault-0 -- base64 /tmp/vault_bkup.tgz | base64 -d - > ~/Downloads/vault_bkup.tgz
```
