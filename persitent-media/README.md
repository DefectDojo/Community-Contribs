## Introduction

When deploying DD from official HELM, it doesn't support persistent storage out of the box for user uploaded content as part of a test. Even HELM mounts into container k8s emptyDir type of volumes this type of volume is not persistent (ephemeral) and is not possible to share content between the pods, so it means content will disappear together with pod and there is no possibility to scale django pods.

## Solution

From HELM version 1.6.15, it is possible to map `media paths` to some persistent storage, that supports persistence of data, and `R/W MANY` so multiple pods can access the same content, to have a unique view.

```yaml
django:
  mediaPersistentVolume:
    enabled: true
    type: pvc
    name: media-images
    persistentVolumeClaim: images
```

### Requirements

To enable permanent storage there should be K8S PVC created in advance and should be a file system that supports read/write from multiple sources at the same time. GlusterFS, S3, NFS, etc. are types of filesystems that are supporting requirements.

### Example

This example shows how to create enable persistent volume using [minIO](https://min.io) as S3 provider and [data-shim](https://datashim-io.github.io/datashim/) to create PVC.

First, there should be S3 available, for this example, we will use [single pod](https://github.com/datashim-io/datashim/tree/master/examples/minio) implementation of minIO (for production should be in use deployment using minIO operator to enable resilient solution).

```bash
kubectl apply -f .
deployment.apps/minio created
secret/minio-conf created
service/minio-service created
kubectl get pods -n dlf
NAME                    READY   STATUS    RESTARTS   AGE
minio-7dc8d655d-2xth7   1/1     Running   0          2m34s
```
NOTE: Do not use default Access Credentials.

Now minIO is running, and we should enable `datashim` so we can automatically create PVC.

For that reason, we need to clone [datashim] and use HELM chart from there.

```bash
helm install dlf --namespace dlf  --set csi-s3-chart.enabled=true --set csi-nfs-chart.enabled=false --set csi-h3-chart.enabled=false  --set csi-s3-chart.mounter=rclone .
NAME: dlf
LAST DEPLOYED: Tue Oct  5 11:03:10 2021
NAMESPACE: dlf
STATUS: deployed
REVISION: 1
TEST SUITE: None
kubectl get pods -n dlf
NAME                                READY   STATUS    RESTARTS   AGE
csi-attacher-s3-0                   1/1     Running   0          2m13s
csi-provisioner-s3-0                1/1     Running   0          2m13s
csi-s3-rw9lh                        2/2     Running   0          2m13s
dataset-operator-644f75fcbb-mbrnb   1/1     Running   0          2m13s
minio-7dc8d655d-2xth7               1/1     Running   0          12m

```

Now we can declare access parameters as environment variables as:

```bash
export AWS_ACCESS_KEY_ID=from_minio
export AWS_SECRET_ACCESS_KEY=from_mino
export S3_SERVICE_URL=minio_service #this example http://minio-service.dlf:9000
export BUCKET_NAME=anyName
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: com.ie.ibm.hpsys/v1alpha1
kind: Dataset
metadata:
  name: media
spec:
  local:
    type: "COS"
    accessKeyID: "${AWS_ACCESS_KEY_ID}"
    secretAccessKey: "${AWS_SECRET_ACCESS_KEY}"
    endpoint: "${S3_SERVICE_URL}"
    bucket: "${BUCKET_NAME}"
    readonly: "false" #OPTIONAL, default is false
    region: "" #OPTIONAL
    provision: "true"
EOF
kubectl get pvc
NAME    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
media   Bound    pvc-05249390-bf97-4cb5-9b54-41b657beb743   9314Gi     RWX            csi-s3         57s
```

Now we can see that PVC is ready to be consumed by DD, so we can simple deploy DD with customized values:

```yaml
django:
  mediaPersistentVolume:
    enabled: true
    type: pvc
    name: media-images
    persistentVolumeClaim: media
```

Now we can check that everything is ok

```bash
kubectl describe deployment -l defectdojo.org/component=django
...
Mounts:
      /app/media from media (rw)
      /run/defectdojo from run (rw)
...
media-images:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  media
    ReadOnly:   false
```

And for the final check, we can upload one of the files to into one of the tests, an see inside of minIO, is file really there.

```bash
kubectl port-forward -n dlf service/minio-service 9000:9000
```

And then open a browser to http://localhost:9000

