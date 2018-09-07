```bash
FOUNDATION_URL=https://opsmgr-01.haas-174.pez.pivotal.io/
  # Get the UAA token for API request
uaac target $FOUNDATION_URL/uaa --skip-ssl-validation
uaac token owner get
uaac context
UAA_ACCESS_TOKEN=eyJhbG…
curl "$FOUNDATION_URL/api/v0/staged/products" -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -k
CF_GUID=cf-dff86efd769a495886b2
curl "$FOUNDATION_URL/api/v0/staged/products/$CF_GUID/jobs" -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -k
curl "$FOUNDATION_URL/api/v0/staged/products/$CF_GUID/jobs" -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -k | jq -r '.jobs[] | select(.name=="router" or .name=="diego_brain" or .name=="tcp_router")'

set -- \
  router router-16b03b5d777d286c0690 http_https_lb \
  diego_brain diego_brain-1d4b4c1b739932a96c89 ssh_lb \
  tcp_router tcp_router-5e950d954b1bcb945681 tcp_lb

while [ $# -gt 0 ]; do
  JOB_NAME=$1
  JOB_GUID=$2
  LB_NAME=$3
  curl "$FOUNDATION_URL/api/v0/staged/products/$CF_GUID/jobs/$JOB_GUID/resource_config" -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -k |
     jq ".additional_vm_extensions |= . + [\"$LB_NAME\"]" > \
     $JOB_NAME-resource-config.json
  shift 3
done

for VM_EXTENSION_FILE in {router,diego_brain,tcp_router}_vm-extension.json; do
  curl "$FOUNDATION_URL/api/v0/staged/vm_extensions" -X POST -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -d "@${VM_EXTENSION_FILE}" -H "Content-Type: application/json" -k
done

set -- \
  router router-16b03b5d777d286c0690 \
  diego_brain diego_brain-1d4b4c1b739932a96c89 \
  tcp_router tcp_router-5e950d954b1bcb945681

while [ $# -gt 0 ]; do
  RESOURCE_CONFIG_FILE=${1}-resource-config.json
  JOB_GUID=$2
  curl "$FOUNDATION_URL/api/v0/staged/products/${CF_GUID}/jobs/${JOB_GUID}/resource_config" -X PUT -H "Authorization: Bearer $UAA_ACCESS_TOKEN" -d "@${RESOURCE_CONFIG_FILE}" -H "Content-Type: application/json" -k
  shift 2
done
```
