DISCLAIMER: This configuration has been tested on GKE with Autopilot enabled. Working example is not optimized for production, but demonstrates how DefectDojo can be deployed on top of the GKE platform.

Prerequisites:
- GKE cluster with proper access
- Prepared FQDN for static IP address

1. I would recommend using a static global IP address to avoid an ephemeral one for the NLB.

```bash
gcloud compute addresses create dd-ip --project=gke-project --global
gcloud   compute addresses  list  --project=gke-project
NAME   ADDRESS/RANGE  TYPE      PURPOSE  NETWORK  REGION  SUBNET  STATUS
dd-ip  x.x.x.x    EXTERNAL                                    RESERVED
```

2. Now register the IP address to its FQDN and check that is resolvable by Google

```bash
host dd-test.example.com 8.8.8.8
Using domain server:
Name: 8.8.8.8
Address: 8.8.8.8#53
Aliases:

dd-test.example.com has the address x.x.x.x
```

3. Configure values like (e.g. gke-vals.yaml):

```yaml

host: dd-test.example.com

django:
  ingress:
    enabled: true
    activateTLS: false
    annotations:
      kubernetes.io/ingress.global-static-ip-name: "dd-ip"

gke:
  useGKEIngress: true
  useManagedCertificate: true
```

3. Apply the configuration (on top of other parameters you want to change from the default one)

```bash
helm upgrade -i  dd-1 -f gke-vals.yaml helm-charts/defectdojo
```

NOTE: Processioning of the cert takes some time, and you may face timeout from the `helm` command. You can trace progress in Certification Manager
