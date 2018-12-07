#!/usr/bin/env bash
#
# Warning: DO NOT use this script in isolation. It assumes certain environments variables to be set to work. It's split up in a separate file for readability
#
#

function ask_to_continue() {
    if [[ -z ${NO_PROMPT+x} ]];then
        echo -n "${1} (Y|n): "
        read cont
        if [[ ! $cont == 'n' && ! $cont == 'Y' ]];then
            echo "Not a valid input $cont"
            ask_to_continue $1
        fi
        if [[ $cont == "n" ]];then
            return 1
        else
            return 0
        fi
    else
       return 0
    fi
}

function execute_gcloud_command() {

    echo "executing gcloud command: ${1}"
    eval "${1} >> ${GCLOUD_LOG_FILE} 2>&1"
}

function execute_kubectl_command() {
    echo "executing kubectl command: ${1}"
    eval "${1} >> ${KUBE_LOG_FILE} 2>&1"
}

function read_file_to_variable() {
    file_name=$1
    variable=$(eval "cat <<EOF
$(<$file_name)
EOF")
    echo "$variable"
}
