#!/usr/bin/env bash

#
# Warning: DO NOT use this script in isolation. It assumes certain environments variables to be set to work. It's split up in a separate file for readability
#
#

. ${UTIL_DIR}/common.sh

function generate_certs() {
  echo "generating certificates for kube components.."
  cd ${CERT_DIR}

  cp ${CERT_TEMPLATE_DIR}/ca-config.json ${CERT_DIR}
  cp ${CERT_TEMPLATE_DIR}/ca-csr.json ${CERT_DIR} 

  cfssl gencert -initca ca-csr.json | cfssljson -bare ca

  cp ${CERT_TEMPLATE_DIR}/admin-csr.json ${CERT_DIR}

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    admin-csr.json | cfssljson -bare admin

  for i in 0 1 2;do
      instance=${WORKER_INSTANCE[$i]}
      csr_json=$(read_file_to_variable ${CERT_TEMPLATE_DIR}/worker-csr.json)
      echo "${csr_json}" > ${CERT_DIR}/${instance}-csr.json
      cfssl gencert \
          -ca=ca.pem \
          -ca-key=ca-key.pem \
          -config=ca-config.json \
          -hostname=${instance},${WORKER_IP_INTERNAL[$i]},${WORKER_IP_EXTERNAL[$i]} \
          -profile=kubernetes \
      ${instance}-csr.json | cfssljson -bare ${instance}
  done

  cp ${CERT_TEMPLATE_DIR}/kube-controller-manager-csr.json ${CERT_DIR}

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

  cp ${CERT_TEMPLATE_DIR}/kube-proxy-csr.json ${CERT_DIR}

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-proxy-csr.json | cfssljson -bare kube-proxy
 
  cp ${CERT_TEMPLATE_DIR}/kube-scheduler-csr.json ${CERT_DIR}

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-scheduler-csr.json | cfssljson -bare kube-scheduler

  cp ${CERT_TEMPLATE_DIR}/kubernetes-csr.json ${CERT_DIR}
   
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=10.38.0.1,${CONTROLLER_IP_LIST_INTERNAL},${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes

  cp ${CERT_TEMPLATE_DIR}/service-account-csr.json ${CERT_DIR}

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    service-account-csr.json | cfssljson -bare service-account

  echo "done generating certificates in ${CERT_DIR}"

  ask_to_continue "would you like to deploy certificates to workers and controllers?"
  if [[ $? == 0 ]];then
      for i in 0 1 2; do
              instance=${WORKER_INSTANCE[$i]}
              instance_ip=${WORKER_IP_EXTERNAL[$i]}
              scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ca.pem ${instance}-key.pem ${instance}.pem ${instance_ip}:~/
          done
          for i in 0 1 2; do
              instance=${CONTROLLER_INSTANCE[$i]}
              controller_ip=${CONTROLLER_IP_EXTERNAL[$i]}
              scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem ${controller_ip}:~/
          done
  fi

}
