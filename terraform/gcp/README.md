### Terraform: Provision GKE Cluster

The Terraform templates were taken from the repo,
<https://github.com/hashicorp/learn-terraform-provision-gke-cluster>, a
companion repo to the [Provision a GKE Cluster learn
guide](https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster),
containing Terraform configuration files to provision an GKE cluster on GCP.

This repo also creates a VPC and subnet for the GKE cluster. This is not
required but highly recommended to keep your GKE cluster isolated.

### Quick Start

```
terraform apply
gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --zone $(terraform output -raw zone)
```

### Creating the NGINX Ingress Controller

Official docs: <https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke>.

Setting up the load balancer is as simple as `kubectl apply`. I have customized:

```zsh
kubectl apply -f nginx-ingress-controller.yml
```
Check the installed version
```zsh
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- /nginx-ingress-controller --version
```

### TLS

Docs from <https://cert-manager.io/docs/tutorials/acme/ingress/>

Let's install the sample services to test the controller:
```
kubectl apply -f https://netlify.cert-manager.io/docs/tutorials/acme/example/deployment.yaml
kubectl apply -f https://netlify.cert-manager.io/docs/tutorials/acme/example/service.yaml
```

Let's download and edit the Ingress:
```
curl -o ingress-kuard.yml -L https://netlify.cert-manager.io/docs/tutorials/acme/example/ingress.yaml
sed -i '' "s/example.example.com/gke.nono.io/g" ingress-kuard.yml
```

Let's use curl to check (note the cert is still self-signed at this point):
```
curl -kivL -H 'Host: gke.nono.io' 'http://34.70.157.237'
```

#### Install cert-manager

We choose to install with regular manifests (not `helm`):
```
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
```

(I did not seem to run into the GKE `permission denied` error that they warn
about). Let's check that the 3 pods are up & running:

```
kubectl get pods --namespace cert-manager
```
