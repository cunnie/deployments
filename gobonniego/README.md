## GoBonnieGo assets

This directory contains the Cloud Configs and manifests for using
the _GoBonnieGo_ BOSH release to benchmark IaaSes.

| IaaS      | Instance Type   | Cores   | RAM (GiB)   | Disk Type       |
| --------- | --------------- | ------- | ----------- | --------------  |
| AWS       | c4.xlarge       | 4       | 7.5         | standard        |
|           |                 |         |             | gp2             |
|           |                 |         |             | io1             |
| Azure     | F4 v2           | 4       | 8           | Standard        |
|           |                 |         |             | Premium 20 GiB  |
|           |                 |         |             | Premium 256 GiB |
| Google    | n1-highcpu-8    | 8       | 7.2         | pd-standard     |
|           |                 |         |             | pd-ssd          |
| vSphere   | N/A             | 8       | 8           | FreeNAS         |
|           |                 |         |             | SATA SSD        |
|           |                 |         |             | NVMe SSD        |
