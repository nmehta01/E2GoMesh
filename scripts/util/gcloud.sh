#!/usr/bin/env bash

#
# Warning: DO NOT use this script in isolation. It assumes certain environments variables to be set to work. It's split up in a separate file for readability
#
#

. ${UTIL_DIR}/common.sh


function create_gcloud_resources() {
    
    gcloud init

    SSH_IDENTITY_FILE="~/.ssh/google_compute_engine"

    write_to_env_file "SSH_IDENTITY_FILE"
    
    echo "creating network..."
    net_create="gcloud compute networks create ${NETWORK_NAME} --subnet-mode custom"
    execute_gcloud_command "${net_create}"

    echo "creating subnet..."
    subnet_create="gcloud compute networks subnets create ${PRIMARY_SUBNET_NAME} --network ${NETWORK_NAME} --range ${PRIMARY_SUBNET_CIDR}"
    execute_gcloud_command "${subnet_create}"
    
    echo "creating f/w rules to allow ALL traffic from primary subnet to secondary"
    fw_create="gcloud compute firewall-rules create ${PREFIX}-allow-internal-all --allow tcp,udp,icmp --network ${NETWORK_NAME}  --source-ranges ${PRIMARY_SUBNET_CIDR},${CLUSTER_CIDR}"
    execute_gcloud_command "${fw_create}"

    echo "creating f/w rules to allow ssh, ssl, icmp traffic from outside to the primary network"
    fw_create="gcloud compute firewall-rules create  ${PREFIX}-allow-external-ssh-icmp-ssl --allow tcp:22,tcp:6443,icmp --network ${NETWORK_NAME} --source-ranges 0.0.0.0/0"
    execute_gcloud_command "${fw_create}"

    echo "creating static IP"
    sip_create="gcloud compute addresses create ${NETWORK_NAME} --region $(gcloud config get-value compute/region)"
    execute_gcloud_command "${sip_create}"
    KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe ${NETWORK_NAME} --region $(gcloud config get-value compute/region) --format 'value(address)')
    echo "the static ip for the cluster will be ${KUBERNETES_PUBLIC_ADDRESS}"
    write_to_env_file "KUBERNETES_PUBLIC_ADDRESS"

    echo "creating controller nodes"
    for i in 0 1 2; do
        echo "creating controller node ${PREFIX}-controller-${i} with internal ip ${CONTROLLER_IP_PREFIX}${i}"
        controller_setup=$(cat <<-END
        gcloud compute instances create ${PREFIX}-controller-${i} \
        --async \
        --boot-disk-size 200GB \
        --can-ip-forward \
        --image-family ubuntu-1804-lts \
        --image-project ubuntu-os-cloud \
        --machine-type n1-standard-1 \
        --private-network-ip ${CONTROLLER_IP_PREFIX}${i} \
        --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
        --subnet ${PRIMARY_SUBNET_NAME} \
        --tags ${NETWORK_NAME},controller
END
)
    execute_gcloud_command "${controller_setup}"
    done

    echo "creating worker nodes"
    for i in 0 1 2; do
        echo "creating worker node ${PREFIX}-worker-${i} with internal ip ${WORKER_IP_PREFIX}${i}"
        clust_ip=${POD_CLUSTER_EXPR/"i"/"$i"}
        worker_setup=$(cat <<-END
        gcloud compute instances create ${PREFIX}-worker-${i} \
        --async \
        --boot-disk-size 200GB \
        --can-ip-forward \
        --image-family ubuntu-1804-lts \
        --image-project ubuntu-os-cloud \
        --machine-type n1-standard-1 \
        --metadata pod-cidr=${clust_ip} \
        --private-network-ip ${WORKER_IP_PREFIX}${i} \
        --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
        --subnet ${PRIMARY_SUBNET_NAME} \
        --tags ${NETWORK_NAME},worker
END
)
    execute_gcloud_command "${worker_setup}"
    done
    WORKER_IP_LIST_INTERNAL=''
    WORKER_IP_LIST_EXTERNAL=''
    for i in 0 1 2; do
        instance=${PREFIX}-worker-${i}
        WORKER_INSTANCE[${i}]=${instance}
        WORKER_IP_INTERNAL[${i}]=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].networkIP)')
        WORKER_IP_EXTERNAL[${i}]=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
        WORKER_IP_LIST_INTERNAL="${WORKER_IP_LIST_INTERNAL}${WORKER_IP_INTERNAL[${i}]},"
        WORKER_IP_LIST_EXTERNAL="${WORKER_IP_LIST_EXTERNAM}${WORKER_IP_EXTERNAL[${i}]},"
    done

    CONTROLLER_IP_LIST_EXTERNAL=''
    CONTROLLER_IP_LIST_INTERNAL=''
    CONTROLLER_INSTANCE_LIST=''

    for i in 0 1 2; do
        instance=${PREFIX}-controller-${i}
        CONTROLLER_INSTANCE[${i}]=${instance}
        CONTROLLER_IP_INTERNAL[${i}]=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].networkIP)')
        CONTROLLER_IP_EXTERNAL[${i}]=$(gcloud compute instances describe ${instance} --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
        CONTROLLER_IP_LIST_EXTERNAL="${CONTROLLER_IP_LIST_EXTERNAL}${CONTROLLER_IP_EXTERNAL[${i}]},"
        CONTROLLER_IP_LIST_INTERNAL="${CONTROLLER_IP_LIST_INTERNAL}${CONTROLLER_IP_INTERNAL[${i}]},"
        CONTROLLER_INSTANCE_LIST="${CONTROLLER_INSTANCE_LIST}${CONTROLLER_INSTANCE[${i}]},"
    done

    CONTROLLER_IP_LIST_EXTERNAL="${CONTROLLER_IP_LIST_EXTERNAL%?}"
    CONTROLLER_IP_LIST_INTERNAL="${CONTROLLER_IP_LIST_INTERNAL%?}"
    CONTROLLER_INSTANCE_LIST="${CONTROLLER_INSTANCE_LIST%?}"
    WORKER_IP_LIST_INTERNAL="${WORKER_IP_LIST_INTERNAL%?}"
    WORKER_IP_LIST_EXTERNAL="${WORKER_IP_LIST_EXTERNAL%?}"

    write_to_env_file "CONTROLLER_IP_LIST_EXTERNAL"
    write_to_env_file "CONTROLLER_IP_LIST_INTERNAL"
    write_to_env_file "CONTROLLER_INSTANCE_LIST"
    write_to_env_file "WORKER_IP_LIST_INTERNAL"
    write_to_env_file "WORKER_IP_LIST_EXTERNAL"

    echo "The following resources are created..."
    print_fix_width "instance name" "internal ip" "external ip"
    print_fix_width "${DASHES}" "${DASHES}" "${DASHES}"
    
    for i in 0 1 2; do
        print_fix_width ${WORKER_INSTANCE[${i}]} ${WORKER_IP_INTERNAL[${i}]} ${WORKER_IP_EXTERNAL[${i}]}
    done
    
    for i in 0 1 2; do
        print_fix_width ${CONTROLLER_INSTANCE[${i}]} ${CONTROLLER_IP_INTERNAL[${i}]} ${CONTROLLER_IP_EXTERNAL[${i}]}
    done
    
}

function create_external_gcloud_lb() {

    health_check_create=$(cat <<-END

    gcloud compute http-health-checks create ${PREFIX}-kubernetes-hc \
    --description "Kubernetes Health Check for cluster ${CLUSTER_NAME}" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"
END
)

    execute_gcloud_command "${health_check_create}"

   fw_open=$(cat <<-END
    gcloud compute firewall-rules create ${NETWORK_NAME}-allow-health-check \
    --network ${NETWORK_NAME} \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp
END
)
    execute_gcloud_command "${fw_open}"

    create_pool=$(cat <<-END
    gcloud compute target-pools create ${PREFIX}-kubernetes-target-pool --http-health-check ${PREFIX}-kubernetes-hc
END
)
    execute_gcloud_command "${create_pool}"

    add_to_pool=$(cat <<-END
    gcloud compute target-pools add-instances ${PREFIX}-kubernetes-target-pool --instances ${CONTROLLER_INSTANCE_LIST}
END
)
    execute_gcloud_command "${add_to_pool}"

    fwd_rule=$(cat <<-END
    gcloud compute forwarding-rules create ${PREFIX}-kubernetes-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region $(gcloud config get-value compute/region) \
    --target-pool ${PREFIX}-kubernetes-target-pool
END
)
    execute_gcloud_command "${fwd_rule}"
    
    echo "verifying load balancer"
    curl --cacert ${CERT_DIR}/ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
}

function create_gcloud_pod_routes() {
    
    for i in 0 1 2; do
       clust_ip="${POD_CLUSTER_EXPR/"i"/"$i"}"
       route_name=${PREFIX}-kubernetes-route-${clust_ip//[\/|.]/-}
       cmd="gcloud compute routes create ${route_name} --network ${NETWORK_NAME} --next-hop-address ${WORKER_IP_INTERNAL[$i]}  --destination-range ${clust_ip}"
       execute_gcloud_command "${cmd}"
    done

    echo "Network routes are: "
    gcloud compute routes list --filter "network: ${NETWORK_NAME}"

}

