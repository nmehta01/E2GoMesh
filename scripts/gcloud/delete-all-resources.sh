#!/usr/bin/env bash

usage() {

    echo deletes all gcloud compute instances that match the given regular expression
    echo usage: delete-instances.sh REGEX
    exit 1
}

if [[ -z $1 ]]; then
    usage
fi

REGEX=$1

ALL_INSTANCES=$(gcloud compute instances list --filter="name~'$REGEX'" | grep $REGEX | awk '{print $1;}')
if [[ -z $ALL_INSTANCES ]];then
    echo "No instances found"
fi

ALL_FW_RULES=$(gcloud compute firewall-rules list --filter="name~'$REGEX'" --format="table(name)" | grep $REGEX | awk '{print $1;}')
if [[ -z $ALL_FW_RULES ]];then
    echo "No firewall rules found"
fi

ALL_NETWORKS=$(gcloud compute networks list --filter="name~'$REGEX'" | grep $REGEX | awk '{print $1;}')
if [[ -z $ALL_NETWORKS ]];then
    echo "No networks found"
fi

ALL_SUBNETS=$(gcloud compute networks subnets list --filter="name~'$REGEX'" | grep $REGEX | awk '{print $1;}')
if [[ -z $ALL_SUBNETS ]];then
    echo "No subnets found"
fi

ALL_STATIC_IPS=$(gcloud compute addresses list --filter="name~'$REGEX'"  | grep $REGEX | awk '{print $1;}')

echo "will DELETE the following: "
echo "Instances: $ALL_INSTANCES"
echo "Networks: $ALL_NETWORKS"
echo "Firewall Rules: $ALL_FW_RULES"
echo "Subnets: $ALL_SUBNETS"
echo "Static IPs: $ALL_STATIC_IPS"
echo -n "Proceed? [y|n]: "

read proceed

if [[  $proceed = "y" ]];then
    for instance in $ALL_INSTANCES; do
        echo "deleting compute instance $instance"
        gcloud compute instances delete $instance --quiet
    done

    for fw in $ALL_FW_RULES;do
        echo "deleting firewall rule $fw"
        gcloud compute firewall-rules delete $fw --quiet
    done

    for subnet in $ALL_SUBNETS;do
        echo "deleting subnet $subnet"
        gcloud compute networks subnets delete $subnet --quiet
    done

    for network in $ALL_NETWORKS; do
        echo "deleting network $network"
        gcloud compute networks delete $network --quiet
    done
    
    for ip in $ALL_STATIC_IPS; do
        echo "deleting static ip $ip"
        gcloud compute addresses delete $ip --quiet
    done

fi 
