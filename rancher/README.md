# Rancher
This is meant to help facilitate deploying DefectDojo in a Rancher/Kubernetes environment. This grabs the containers from the Docker registry and instantiates them in a pod. The ports are exposed for communication, MySQL gets a persistent volume, everyone is happy.

### deployment.yaml
Based off the docker-compose.yaml and translated to Kubernetes. MySQL uses a persistent volume claim, so comment out the MySQL lines in this file if you don't intend on using the MySQL container.

### service.yaml
Exposes the containers's ports within the pod.

### pv.yaml
Persistent volume using the NFS client for the MySQL volume. If MySQL is external, you probably don't need this. Adjust as needed.

### ingress.yaml
Rancher's ingress yaml for serving HTTPS requests. Replace the URL with your appropriate URL.
