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

Official docs: <https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke>

```zsh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)
kubectl get pods -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx --watch
```
Check the installed version
```zsh
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- /nginx-ingress-controller --version
```
