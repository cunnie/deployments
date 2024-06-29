```bash
terraform init --upgrade
terraform apply -auto-approve
# to destroy
# terraform state list
# terraform apply -target=google_compute_instance.vm_instance -destroy -auto-approve
```

```bash
gcloud compute ssh --zone "us-central1-a" "ns-gce" --project "blabbertabber"
tail -f /var/log/cloud-init-output.log
bin/install_ns-gce.sh
```
