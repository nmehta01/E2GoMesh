BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export TEMPLATE_DIR=${BASE_DIR}/templates
export CERT_TEMPLATE_DIR=${TEMPLATE_DIR}/certs
export CONTROL_PLANE_TEMPLATE_DIR=${TEMPLATE_DIR}/control-plane
export ENCRYPTION_TEMPLATE_DIR=${TEMPLATE_DIR}/encryption
export RBAC_TEMPLATE_DIR=${TEMPLATE_DIR}/rbac
export ETCD_TEMPLATE_DIR=${TEMPLATE_DIR}/etcd
export WORKER_TEMPLATE_DIR=${TEMPLATE_DIR}/worker
export UTIL_DIR=${BASE_DIR}/util

