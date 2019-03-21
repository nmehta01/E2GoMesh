#!/bin/bash

export ISTIO_VERSION=1.0.6
function setupGKECluster(){

    gcloud init
    echo -n "Please provide a name for your cluster: "
	read  CLUSTER_NAME 

	gcloud container clusters create $CLUSTER_NAME \
	 --cluster-version=latest \
     --zone=$(gcloud config get-value compute/zone) \
	 --num-nodes 4
         
	gcloud container clusters list | grep $CLUSTER_NAME


	kubectl create clusterrolebinding cluster-admin-binding \
  	--clusterrole=cluster-admin \
	--user=$(gcloud config get-value core/account)
}

function downloadIstio(){
    OS="$(uname)"
    if [ "x${OS}" = "xDarwin" ] ; then
        OSEXT="osx"
    else
        # TODO we should check more/complain if not likely to work, etc...
        OSEXT="linux"
    fi
    NAME="istio-$ISTIO_VERSION"
    URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-${OSEXT}.tar.gz"
    echo "Downloading $NAME from $URL ..."
    curl -L "$URL" | tar xz    
    # TODO: change this so the version is in the tgz/directory name (users trying multiple versions)
    echo "Downloaded into $NAME:"
}

function deployIstio(){
    echo "deploying istio..."
    kubectl apply -f ./istio-1.0.6/install/kubernetes/istio-demo.yaml
    echo "waiting for 2 mins for Istio components to come up"
    sleep 120
    kubectl create namespace bookinfo
    kubectl get pods -n istio-system
    kubectl label namespace bookinfo  istio-injection=enabled
    kubectl get namespace -L istio-injection
    
    echo "exposing istio services to the outside world"
    kubectl patch svc tracing -p '{"spec":{"type":"LoadBalancer"}}' -n istio-system
    kubectl patch svc servicegraph -p '{"spec":{"type":"LoadBalancer"}}' -n istio-system
    kubectl patch svc prometheus -p '{"spec":{"type":"LoadBalancer"}}' -n istio-system
    kubectl patch svc zipkin -p '{"spec":{"type":"LoadBalancer"}}' -n istio-system
    kubectl patch svc grafana -p '{"spec":{"type":"LoadBalancer"}}' -n istio-system
    
    echo "waiting for 5 mins for services to obtain ip addresses"
    sleep 300
    
    export TRACING_URL="http://$(kubectl -n istio-system get service tracing -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"    
    export SERVICEGRAPH_URL="http://$(kubectl -n istio-system get service tracing -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8088/force/forcegraph.html"
    export PROMETHEUS_URL="http://$(kubectl -n istio-system get service prometheus -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):9090/graph"
    export ZIPKIN_URL="http://$(kubectl -n istio-system get service zipkin -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):9411/zipkin/"
    export GRAFANA_URL="http://$(kubectl -n istio-system get service grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):3000"
    export APP_URL="http://$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/productpage"

    echo "URL for the Application: ${APP_URL}"
    echo "Tracing URL: ${TRACING_URL}"
    echo "Service Graph URL: ${SERVICEGRAPH_URL}"
    echo "Prometheus URL: ${PROMETHEUS_URL}"
    echo "Zipkin URL: ${ZIPKIN_URL}"
    echo "Grafana URL: ${GRAFANA_URL}"
}

setupGKECluster
downloadIstio
deployIstio

