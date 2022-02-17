#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This script tests TCE Standalone cluster in Azure.
# It builds TCE, spins up a standalone cluster in Azure,
# installs the default packages,
# and cleans the environment.
# Note: This script supports only Linux(Debian) and MacOS
# Following environment variables need to be exported before running the script
# AZURE_TENANT_ID
# AZURE_SUBSCRIPTION_ID
# AZURE_CLIENT_ID
# AZURE_CLIENT_SECRET
# AZURE_SSH_PUBLIC_KEY_B64
# Azure location is set to australiacentral using AZURE_LOCATION

set -e
set -x

TCE_REPO_PATH="$(git rev-parse --show-toplevel)"

declare -a required_env_vars=("AZURE_CLIENT_ID"
"AZURE_CLIENT_SECRET"
"AZURE_SSH_PUBLIC_KEY_B64"
"AZURE_SUBSCRIPTION_ID"
"AZURE_TENANT_ID")

"${TCE_REPO_PATH}/test/azure/check-required-env-vars.sh" "${required_env_vars[@]}"

# shellcheck source=test/util/utils.sh
source "${TCE_REPO_PATH}/test/util/utils.sh"
# shellcheck source=test/azure/lib.sh
source "${TCE_REPO_PATH}/test/azure/lib.sh"

"${TCE_REPO_PATH}/test/install-dependencies.sh" || { error "Dependency installation failed!"; exit 1; }
"${TCE_REPO_PATH}/test/build-tce.sh" || { error "TCE installation failed!"; exit 1; }

export CLUSTER_NAME="test${RANDOM}"
echo "Setting CLUSTER_NAME to ${CLUSTER_NAME}..."

export AZURE_RESOURCE_GROUP="${CLUSTER_NAME}-resource-group"
export AZURE_VNET_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}"
export AZURE_VNET_NAME="${CLUSTER_NAME}-vnet"
export AZURE_CONTROL_PLANE_SUBNET_NAME="${CLUSTER_NAME}-control-plane-subnet"
export AZURE_NODE_SUBNET_NAME="${CLUSTER_NAME}-worker-node-subnet"

export VM_IMAGE_PUBLISHER="vmware-inc"
# The value k8s-1dot21dot2-ubuntu-2004 comes from latest TKG BOM file based on OS arch, OS name and OS version
# provided in test/azure/cluster-config.yaml
export VM_IMAGE_BILLING_PLAN_SKU="k8s-1dot21dot2-ubuntu-2004"
export VM_IMAGE_OFFER="tkg-capi"

accept_vm_image_terms || exit 1

create_standalone_cluster || {
    collect_standalone_cluster_diagnostics azure ${CLUSTER_NAME}
    delete_kind_cluster
    cleanup_standalone_cluster
    exit 1
}

wait_for_pods || {
    collect_standalone_cluster_diagnostics azure ${CLUSTER_NAME}
    delete_standalone_cluster_or_cleanup
    exit 1
}

add_package_repo || {
    collect_standalone_cluster_diagnostics azure ${CLUSTER_NAME}
    delete_standalone_cluster_or_cleanup
    exit 1
}

list_packages || {
    collect_standalone_cluster_diagnostics azure ${CLUSTER_NAME}
    delete_standalone_cluster_or_cleanup
    exit 1
}

test_gate_keeper_package || {
    collect_standalone_cluster_diagnostics azure ${CLUSTER_NAME}
    delete_standalone_cluster_or_cleanup
    exit 1
}

echo "Cleaning up..."
delete_standalone_cluster_or_cleanup
