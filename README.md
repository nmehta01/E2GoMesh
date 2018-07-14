# E2GoMesh
Public repository for experimenting with Kube + Service Mesh.

**Table of Contents**
- [Kubernetes](#Kubernetes)
   - [Learning Resources](#learning-resources)
- [gcloud](#gcloud)
   - [Project Conventions](#project-conventions)
***

# Kubernetes

### Learning Resources
 * Kubernetes the hard way: https://github.com/kelseyhightower/kubernetes-the-hard-way

# gcloud 
Everything we need to know to effectively use Google Compute Platform.

### Project Conventions
Since we are sharing a single GCP project, we can avoid stepping on each other's toes if we follow some simple conventions for naming our instances and subnet addressing. 

| Team      | Instance Name Prefix | Subnet CIDR    | Controller Manager CIDR |
|-----------|----------------------|----------------|-------------------------|
| Dallas    | dallas-              | 10.240.0.0/24  | 10.200.0.0/16           |
| Houston   | houston-             | 10.10.0.0/24   | 10.100.0.0/16           |
| Bangalore | bangalore-           | 192.168.0.0/24 | 10.300.0.0/16           |
| Flohio    | flohio-              | 172.16.0.0/24  | 10.400.0.0/16           |
| Nishant   | ngm-                 | 10.5.0.0./24   | 10.500.0.0/16           |

In addition, if you want to create your own clusters, feel free to use any prefix and subnet you like as long as it doesn't clash with the above and update the table above.



