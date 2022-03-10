#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This script tests TCE Management and Workload cluster in Azure.
# It builds TCE, spins up a Management and Workload cluster in Azure,
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
# The best way to run this is by calling `make azure-management-and-workload-cluster-e2e-test`
# from the root of the TCE repository.

set -e
set -x
set -o pipefail

TCE_REPO_PATH="$(git rev-parse --show-toplevel)"

declare -a required_env_vars=("AZURE_CLIENT_ID"
"AZURE_CLIENT_SECRET"
"AZURE_SSH_PUBLIC_KEY_B64"
"AZURE_SUBSCRIPTION_ID"
"AZURE_TENANT_ID")

"${TCE_REPO_PATH}/test/azure/check-required-env-vars.sh" "${required_env_vars[@]}"

# shellcheck source=test/util/utils.sh
source "${TCE_REPO_PATH}/test/util/utils.sh"
# shellcheck source=test/azure/utils.sh
source "${TCE_REPO_PATH}/test/azure/utils.sh"

"${TCE_REPO_PATH}/test/install-dependencies.sh" || { error "Dependency installation failed!"; exit 1; }
"${TCE_REPO_PATH}/test/build-tce.sh" || { error "TCE installation failed!"; exit 1; }

export CLUSTER_NAME_SUFFIX="${RANDOM}"
export MANAGEMENT_CLUSTER_NAME="test-mc-${CLUSTER_NAME_SUFFIX}"
export WORKLOAD_CLUSTER_NAME="test-wld-${CLUSTER_NAME_SUFFIX}"

echo "Setting MANAGEMENT_CLUSTER_NAME to ${MANAGEMENT_CLUSTER_NAME}"
echo "Setting WORKLOAD_CLUSTER_NAME to ${WORKLOAD_CLUSTER_NAME}"

export VM_IMAGE_PUBLISHER="vmware-inc"
# The value k8s-1dot21dot5-ubuntu-2004 comes from latest TKG BOM file based on OS arch, OS name and OS version
# provided in test/azure/cluster-config.yaml. This value needs to be changed manually whenever there's going to
# be a change in the underlying Tanzu Framework CLI version (management-cluster and cluster plugins) causing new
# TKr BOMs to be used with new Azure VM images which have different image billing plan SKU
export VM_IMAGE_BILLING_PLAN_SKU="k8s-1dot21dot5-ubuntu-2004"
export VM_IMAGE_OFFER="tkg-capi"

accept_vm_image_terms || exit 1

create_management_cluster || {
    collect_management_cluster_diagnostics ${MANAGEMENT_CLUSTER_NAME}
    delete_kind_cluster
    cleanup_management_cluster
    exit 1
}

check_management_cluster_creation || {
    collect_management_cluster_diagnostics ${MANAGEMENT_CLUSTER_NAME}
    cleanup_management_cluster
    exit 1
}

create_workload_cluster || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

check_workload_cluster_creation || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

add_package_repo || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

list_packages || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

test_gate_keeper_package || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

echo "Cleaning up"

delete_workload_cluster || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

wait_for_workload_cluster_deletion || {
    collect_management_and_workload_cluster_diagnostics azure ${MANAGEMENT_CLUSTER_NAME} ${WORKLOAD_CLUSTER_NAME}
    cleanup_management_and_workload_cluster
    exit 1
}

# since tanzu cluster delete does not delete workload cluster kubeconfig entry
kubeconfig_cleanup ${WORKLOAD_CLUSTER_NAME}

delete_management_cluster || {
    collect_management_cluster_diagnostics ${MANAGEMENT_CLUSTER_NAME}
    delete_kind_cluster
    cleanup_management_cluster
    exit 1
}
