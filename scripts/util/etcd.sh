#!/usr/bin/env bash

#
# Warning: DO NOT use this script in isolation. It assumes certain environments variables to be set to work. It's split up in a separate file for readability
#
#

. ${UTIL_DIR}/common.sh



function bootstrap_etcd() {
    
    
    for i in 0 1 2; do
        instance=${CONTROLLER_INSTANCE[$i]}
        controller_ip=${CONTROLLER_IP_INTERNAL[$i]}
        
        etcd_config=$(read_file_to_variable ${ETCD_TEMPLATE_DIR}/etcd-setup.conf)

        config_file=${ETCD_DIR}/etcd-setup-${instance}.sh
        echo "${etcd_config}" > ${config_file}

        chmod +x ${config_file}
        
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${config_file} ${CONTROLLER_IP_EXTERNAL[$i]}:~/
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[$i]} 'chmod +x etcd-setup-*.sh; ~/etcd-setup-*.sh'         

    done    
    
    echo "running healthcheck on the etcd cluster"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${SSH_IDENTITY_FILE} ${CONTROLLER_IP_EXTERNAL[$i]} 'sudo ETCDCTL_API=3 etcdctl member list --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem'

}

