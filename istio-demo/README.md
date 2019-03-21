# Demo K8s Cluster With Istio and the BookInfo Sample App

## Prerequisites

 - gcloud cli (can be found here: https://cloud.google.com/sdk/)
 - kubectl (can be found here: https://kubernetes.io/docs/tasks/tools/install-kubectl/)
 - OSX or *NIX 

  
  ## Setting Up
  
  Do this the first time to:
  

 - Setup a K8s cluster
 - Create a namespace **bookinfo** and enables auto-injection for it
 - Downloads Istio version 1.0.6 for your platform
 - Deploys Istio along with the default set of services like prometheus, grafana, etc
 - Sets environment variables with all the URLs you need  
   

`     git clone https://github.com/ishmee1/ServiceMesh.git
      cd istio-demo
      source provisionDemoCluster.sh`

 The script will invoke `gcloud init`. Select the option `Re-initialize this configuration [...] with new settings` and select a zone/region that is closest to where you are physically located.
 The script will also ask you for a cluster name and setup a GKE cluster for you with that name and point kubectl to that cluster. 

## Deploying BookInfo

 

    kubectl apply -f istio-1.0.6/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
    kubectl apply -f istio-1.0.6/samples/bookinfo/networking/bookinfo-gateway.yaml -n bookinfo
    echo $APP_URL


 