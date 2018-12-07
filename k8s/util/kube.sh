#!/usr/bin/env bash

#
# Warning: DO NOT use this script in isolation. It assumes certain environments variables to be set to work. It's split up in a separate file for readability
#
#

. ${UTIL_DIR}/common.sh

function generate_config() {
    
    echo "Generating kube configuration"
    cd ${CERT_DIR}

    for i in 0 1 2; do
        
        instance=${WORKER_INSTANCE[$i]}
        kubectl config set-cluster ${CLUSTER_NAME} \
          --certificate-authority=ca.pem \
          --embed-certs=true \
          --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
          --kubeconfig=${instance}.kubeconfig

        kubectl config set-credentials system:node:${instance} \
          --client-certificate=${instance}.pem \
          --client-key=${instance}-key.pem \
          --embed-certs=true \
          --kubeconfig=${instance}.kubeconfig

        kubectl config set-context ${CONTEXT_NAME} \
          --cluster=${CLUSTER_NAME} \
          --user=system:node:${instance} \
          --kubeconfig=${instance}.kubeconfig

        kubectl config use-context ${CONTEXT_NAME} --kubeconfig=${instance}.kubeconfig

    done

    echo "Generating the kube-proxy config file"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-credentials system:kube-proxy \
      --client-certificate=kube-proxy.pem \
      --client-key=kube-proxy-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-context ${CONTEXT_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=system:kube-proxy \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config use-context ${CONTEXT_NAME} --kubeconfig=kube-proxy.kubeconfig

    echo "Generating the controller-manager configuration file"

    kubectl config set-cluster ${CLUSTER_NAME} \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

     kubectl config set-context ${CONTEXT_NAME} \
    --cluster=${CLUSTER_NAME} \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config use-context ${CONTEXT_NAME} --kubeconfig=kube-controller-manager.kubeconfig

    echo "Generating the kube-scheduler configuration file"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-credentials system:kube-scheduler \
      --client-certificate=kube-scheduler.pem \
      --client-key=kube-scheduler-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-context ${CONTEXT_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=system:kube-scheduler \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config use-context ${CONTEXT_NAME} --kubeconfig=kube-scheduler.kubeconfig

    echo "Generating the admin config file"

    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=admin.kubeconfig

    kubectl config set-credentials admin \
      --client-certificate=admin.pem \
      --client-key=admin-key.pem \
      --embed-certs=true \
      --kubeconfig=admin.kubeconfig

    kubectl config set-context ${CONTEXT_NAME}\
      --cluster=${CLUSTER_NAME} \
      --user=admin \
      --kubeconfig=admin.kubeconfig

    kubectl config use-context ${CONTEXT_NAME} --kubeconfig=admin.kubeconfig

    ask_to_continue "Would you like to copy the config files to the worker/controller nodes?" 

    if [[ $? == 0 ]];then
        
        for i in 0 1 2; do
            instance=${WORKER_INSTANCE[$i]}
            instance_ip=${WORKER_IP_EXTERNAL[$i]}
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${instance}.kubeconfig kube-proxy.kubeconfig ${instance_ip}:~/
        done

        for i in 0 1 2; do
            instance=${CONTROLLER_INSTANCE[$i]}
            controller_ip=${CONTROLLER_IP_EXTERNAL[$i]}
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${controller_ip}:~/
        done

    fi

    cd ${PROJ_DIR}    
}

function generate_enc() {

    ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
    enc_key=$(read_file_to_variable ${ENCRYPTION_TEMPLATE_DIR}/encryption-config.yaml)
    echo "${enc_key}" > ${ENCRYPTION_DIR}/encryption-config.yaml
    ask_to_continue "Would you like to deploy the encryption config to the the controllers?"
    if [[ $? == 0 ]];then
      for i in 0 1 2; do
          instance=${CONTROLLER_INSTANCE[$i]}
          controller_ip=${CONTROLLER_IP_EXTERNAL[$i]}
          scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${ENCRYPTION_DIR}/encryption-config.yaml ${controller_ip}:~/
      done
    fi
}

function bootstrap_control_plane() {

    for i in 0 1 2; do

    instance=${CONTROLLER_INSTANCE[$i]}
    internal_ip=${CONTROLLER_IP_INTERNAL[$i]}
    setup_file=${CONTROL_PLANE_DIR}/${instance}-control-plane-setup.sh

    control_plane_setup=$(read_file_to_variable ${CONTROL_PLANE_TEMPLATE_DIR}/control-plane-setup.conf)
 
    echo "${control_plane_setup}" > ${setup_file}
    
    chmod +x ${setup_file}
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${setup_file} ${CONTROLLER_IP_EXTERNAL[$i]}:~/
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[$i]} 'chmod +x *control-plane-setup.sh; ~/*control-plane-setup.sh' 
        
    done

        echo "Running health check on the control plane..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[0]} 'kubectl get componentstatuses --kubeconfig admin.kubeconfig' 

        echo "Testing the nginx proxy..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[0]} 'curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz'            
}
 

function configure_rbac() {



    cp ${RBAC_TEMPLATE_DIR}/rbac.sh ${RBAC_DIR}/

    chmod +x ${RBAC_DIR}/rbac.sh

    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${RBAC_DIR}/rbac.sh ${CONTROLLER_IP_EXTERNAL[0]}:~/
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[0]} '~/rbac.sh'

}

function configure_worker_nodes() {
    
    for i in 0 1 2; do
        POD_CIDR=${POD_CLUSTER_EXPR/"i"/$i}
        instance=${PREFIX}-worker-${i}
        setup_file=${WORKER_DIR}/${instance}-setup.sh
        worker_setup=$(read_file_to_variable ${WORKER_TEMPLATE_DIR}/worker-setup.sh)
        echo "${worker_setup}" > ${setup_file}
        chmod +x ${setup_file}
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${setup_file} ${WORKER_IP_EXTERNAL[$i]}:~/
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${WORKER_IP_EXTERNAL[$i]} '~/*worker*setup.sh'
  done
  
  echo "checking if the nodes are available"
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[0]} 'kubectl get nodes --kubeconfig admin.kubeconfig'
  
}

function configure_local_kubects() {
    
    cd ${CERT_DIR}
    kubectl config set-cluster ${CLUSTER_NAME} --certificate-authority=ca.pem --embed-certs=true --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443
    kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem
    kubectl config set-context ${CONTEXT_NAME} --cluster=${CLUSTER_NAME} --user=admin
    kubectl config use-context ${CONTEXT_NAME}
    
    echo "verifying kubectl..."
    kubectl get componentstatuses
    kubectl get nodes
}

function configure_kube_dns() {

    echo "deploying core-dns"
    kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

    kubectl get pods -l k8s-app=kube-dns -n kube-system

    echo "installing busybox to check if dns resolves correctly"
    kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

    echo "sleeping for 2 mins so the pod can come up"
    sleep 120

    kubectl get pods -o wide --all-namespaces
    POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
    echo "testing dns on pod $POD_NAME"
    kubectl exec -ti $POD_NAME -- nslookup kubernetes

}
