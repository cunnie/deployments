```
terraform apply -var="admin_password=Aa1_$(dd if=/dev/random bs=1 count=6 | base64)"
terraform destroy -var="admin_password=doesnt_matter"
```
