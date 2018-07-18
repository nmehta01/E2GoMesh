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
    echo "No instances found. Check your regex and try again"
    exit 1
fi

echo "will DELETE the following instances: "
echo $ALL_INSTANCES
echo -n "Proceed? [y|n]: "

read proceed

if [[  $proceed = "y" ]];then
    for instance in $ALL_INSTANCES; do
        echo "deleting compute instance $instance"
        gcloud compute instances delete $instance --quiet
    done
fi 

