#!/usr/bin/env bash

usage() {

    echo performs an action all gcloud compute instances that match the given regular expression
    echo usage: on-all-instances.sh REGEX ACTION
    echo ex: on-all-instances.sh abc stop
    exit 1
}

if [[ -z $1 || -z $2 ]]; then
    usage
fi

REGEX=$1
ACTION=$2

ALL_INSTANCES=$(gcloud compute instances list --filter="name~'$REGEX'" | grep $REGEX | awk '{print $1;}')
if [[ -z $ALL_INSTANCES ]];then
    echo "No instances found"
    return 1
fi

echo "will perform [$ACTION] on the following: "
echo "Instances: $ALL_INSTANCES"
echo -n "Proceed? [y|n]: "

read proceed

if [[ $proceed == "y" ]];then
    for instance in $ALL_INSTANCES; do
        gcloud compute instances $ACTION $instance
    done
fi

