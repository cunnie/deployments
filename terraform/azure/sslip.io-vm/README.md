```
terraform output -raw tls_private_key > /tmp/junk.pem
chmod 600 /tmp/junk.pem
ssh -i /tmp/junk.pem cunnie@2603:1040:2:3::a0
```
