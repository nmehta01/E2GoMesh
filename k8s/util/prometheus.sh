#!/usr/bin/env bash

. ${UTIL_DIR}/common.sh

function deploy_prometheus() {

    echo "Installing  prometheus, grafana and alertmanager"
    kubectl create -f ${PROMETHEUS_DIR}/ || true
    kubectl create -f ${PROMETHEUS_DIR}/ || true
    # It can take a few seconds for the above 'create manifests' command to fully create the following resources, so verify the resources are ready before proceeding.
    until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
    until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

    echo "To access prometheus: "
    echo "kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090"
    echo "http://localhost:9090"

    echo "To access grafana: "
    echo "kubectl --namespace monitoring port-forward svc/grafana 3000"
    echo "http://localhost:3000"

    echo "To access alertmanager: "
    echo "kubectl --namespace monitoring port-forward svc/alertmanager-main 9093"
    echo "http://localhost:9093"
}