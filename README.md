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
If you name everything with the same prefix, you can cleanup your entire infrastructure with a single command by using the script [delete-all-resources.sh](scripts/delete-all-resources.sh)


| Team      | Instance Name Prefix | Subnet CIDR    | Controller Manager CIDR |
|-----------|----------------------|----------------|-------------------------|
| Dallas    | dallas-              | 10.240.0.0/24  | 10.200.0.0/16           |
| Houston   | houston-             | 10.10.0.0/24   | 10.100.0.0/16           |
| Bangalore | bangalore-           | 192.168.0.0/24 | 10.30.0.0/16            |
| Flohio    | flohio-              | 172.16.0.0/24  | 10.40.0.0/16            |
| Nishant   | ngm-                 | 10.5.0.0./24   | 10.50.0.0/16            |

In addition, if you want to create your own clusters, feel free to use any prefix and subnet you like as long as it doesn't clash with the above and update the table above.

# Scripts

## [provision-kube](scripts/provision-kube)
This is an interactive script that can quickly do the following:
 * Provision 6 VMs on the Google Compute Platform (3 workers, 3 controllers)
 * Setup a Kubernetes cluster step-by-step so you can see the various different components of Kubernetes
 * Coming soon: 
    * The ability to setup a cluster on any arbitrary hardware (most of the work for this is done already).
    * The ability to resume cluster setup if one of the steps went awry (most of the work for this is done already).
## [delete-all-resources.sh](scripts/delete-all-resources.sh)
Simple script that takes as an argument a regex and deletes all resources matching that regex (don't worry, it tells you exactly what it will delete and ask for confirmation). If you used a prefix to provision your cluster using the provision-kube script, this will come in handy to tear everything down.