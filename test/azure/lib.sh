#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x

TCE_REPO_PATH="$(git rev-parse --show-toplevel)"

function az_docker {
    docker run --user "$(id -u)":"$(id -g)" \
        --volume "${HOME}":/home/az \
        --env HOME=/home/az \
        --rm \
        mcr.microsoft.com/azure-cli az "$@"
}

function azure_login {
    declare -a required_env_vars=("AZURE_CLIENT_ID"
    "AZURE_CLIENT_SECRET"
    "AZURE_SUBSCRIPTION_ID"
    "AZURE_TENANT_ID")

    "${TCE_REPO_PATH}/test/azure/check-required-env-vars.sh" "${required_env_vars[@]}"

    az_docker login --service-principal --username "${AZURE_CLIENT_ID}" --password "${AZURE_CLIENT_SECRET}" \
        --tenant "${AZURE_TENANT_ID}" || {
        error "azure CLI LOGIN FAILED!"
        return 1
    }

    az_docker account set --subscription "${AZURE_SUBSCRIPTION_ID}" || {
        error "azure CLI SETTING ACCOUNT SUBSCRIPTION ID FAILED!"
        return 1
    }
}

function set_azure_env_vars {
    export AZURE_RESOURCE_GROUP="${CLUSTER_NAME}-resource-group"
    export AZURE_VNET_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}"
    export AZURE_VNET_NAME="${CLUSTER_NAME}-vnet"
    export AZURE_CONTROL_PLANE_SUBNET_NAME="${CLUSTER_NAME}-control-plane-subnet"
    export AZURE_NODE_SUBNET_NAME="${CLUSTER_NAME}-worker-node-subnet"
}

function unset_azure_env_vars {
    unset AZURE_RESOURCE_GROUP
    unset AZURE_VNET_RESOURCE_GROUP
    unset AZURE_VNET_NAME
    unset AZURE_CONTROL_PLANE_SUBNET_NAME
    unset AZURE_NODE_SUBNET_NAME
}

function azure_cluster_cleanup {
    declare -a required_env_vars=("CLUSTER_NAME"
    "AZURE_RESOURCE_GROUP")

    "${TCE_REPO_PATH}/test/azure/check-required-env-vars.sh" "${required_env_vars[@]}"

    echo "Cleaning up ${CLUSTER_NAME} cluster resources using azure CLI"

    azure_login || {
        return 1
    }

    az_docker group delete --name "${AZURE_RESOURCE_GROUP}" --yes || {
        error "azure CLI RESOURCE GROUP DELETION FAILED!"
        return 1
    }
}

function accept_vm_image_terms {
    declare -a required_env_vars=("VM_IMAGE_PUBLISHER"
    "VM_IMAGE_OFFER"
    "VM_IMAGE_BILLING_PLAN_SKU"
    "AZURE_SUBSCRIPTION_ID")

    "${TCE_REPO_PATH}/test/azure/check-required-env-vars.sh" "${required_env_vars[@]}"

    azure_login || {
        return 1
    }

    az_docker vm image terms accept --publisher "${VM_IMAGE_PUBLISHER}" --offer "${VM_IMAGE_OFFER}" \
        --plan "${VM_IMAGE_BILLING_PLAN_SKU}" --subscription "${AZURE_SUBSCRIPTION_ID}" || {
        error "azure CLI ACCEPT VM IMAGE TERMS FAILED!"
        return 1
    }
}

function cleanup_management_cluster {
    echo "Using azure CLI to cleanup ${MANAGEMENT_CLUSTER_NAME} management cluster resources"
    export CLUSTER_NAME="${MANAGEMENT_CLUSTER_NAME}"
    set_azure_env_vars
    kubeconfig_cleanup ${CLUSTER_NAME}
    azure_cluster_cleanup || error "MANAGEMENT CLUSTER CLEANUP USING azure CLI FAILED! Please manually delete any ${MANAGEMENT_CLUSTER_NAME} management cluster resources using Azure Web UI"
    unset_azure_env_vars
    unset CLUSTER_NAME
}

function cleanup_workload_cluster {
    echo "Using azure CLI to cleanup ${WORKLOAD_CLUSTER_NAME} workload cluster resources"
    export CLUSTER_NAME="${WORKLOAD_CLUSTER_NAME}"
    set_azure_env_vars
    kubeconfig_cleanup ${CLUSTER_NAME}
    azure_cluster_cleanup || error "WORKLOAD CLUSTER CLEANUP USING azure CLI FAILED! Please manually delete any ${WORKLOAD_CLUSTER_NAME} workload cluster resources using Azure Web UI"
    unset_azure_env_vars
    unset CLUSTER_NAME
}

function cleanup_management_and_workload_cluster {
    cleanup_management_cluster
    cleanup_workload_cluster
}

function create_management_cluster {
    echo "Bootstrapping TCE management cluster on Azure..."
    export CLUSTER_NAME="${MANAGEMENT_CLUSTER_NAME}"
    set_azure_env_vars

    management_cluster_config_file="${TCE_REPO_PATH}"/test/azure/cluster-config.yaml
    time tanzu management-cluster create ${MANAGEMENT_CLUSTER_NAME} --file "${management_cluster_config_file}" -v 10 || {
        error "MANAGEMENT CLUSTER CREATION FAILED!"
        unset_azure_env_vars
        unset CLUSTER_NAME
        return 1
    }

    unset_azure_env_vars
    unset CLUSTER_NAME
}

function check_management_cluster_creation {
    tanzu management-cluster get | grep "${MANAGEMENT_CLUSTER_NAME}" | grep running || {
        error "MANAGEMENT CLUSTER CREATION CHECK FAILED!"
        return 1
    }

    tanzu management-cluster kubeconfig get ${MANAGEMENT_CLUSTER_NAME} --admin || {
        error "ERROR GETTING MANAGEMENT CLUSTER KUBECONFIG!"
        return 1
    }

    "${TCE_REPO_PATH}"/test/check-tce-cluster-creation.sh ${MANAGEMENT_CLUSTER_NAME}-admin@${MANAGEMENT_CLUSTER_NAME} || {
        error "MANAGEMENT CLUSTER CREATION CHECK FAILED!"
        return 1
    }
}

function delete_management_cluster {
    echo "Deleting management cluster"
    time tanzu management-cluster delete ${MANAGEMENT_CLUSTER_NAME} -y || {
        error "MANAGEMENT CLUSTER DELETION FAILED!"
        return 1
    }
}

function create_workload_cluster {
    echo "Creating workload cluster on Azure..."
    export CLUSTER_NAME="${WORKLOAD_CLUSTER_NAME}"
    set_azure_env_vars

    workload_cluster_config_file="${TCE_REPO_PATH}"/test/azure/cluster-config.yaml
    time tanzu cluster create ${WORKLOAD_CLUSTER_NAME} --file "${workload_cluster_config_file}" -v 10 || {
        error "WORKLOAD CLUSTER CREATION FAILED!"
        unset_azure_env_vars
        unset CLUSTER_NAME
        return 1
    }

    unset_azure_env_vars
    unset CLUSTER_NAME
}

function check_workload_cluster_creation {
    tanzu cluster list | grep "${WORKLOAD_CLUSTER_NAME}" | grep running || {
        error "WORKLOAD CLUSTER CREATION CHECK FAILED!"
        return 1
    }

    tanzu cluster kubeconfig get ${WORKLOAD_CLUSTER_NAME} --admin || {
        error "ERROR GETTING WORKLOAD CLUSTER KUBECONFIG!"
        return 1
    }

    "${TCE_REPO_PATH}"/test/check-tce-cluster-creation.sh ${WORKLOAD_CLUSTER_NAME}-admin@${WORKLOAD_CLUSTER_NAME} || {
        error "WORKLOAD CLUSTER CREATION CHECK FAILED!"
        return 1
    }
}

function add_package_repo {
    echo "Installing package repository on TCE..."
    "${TCE_REPO_PATH}"/test/add-tce-package-repo.sh || {
        error "PACKAGE REPOSITORY INSTALLATION FAILED!";
        return 1;
    }
}

function list_packages {
    tanzu package available list || {
        error "LISTING PACKAGES FAILED";
        return 1;
    }
}

function test_gate_keeper_package {
    echo "Starting Gatekeeper test..."
    "${TCE_REPO_PATH}"/test/gatekeeper/e2e-test.sh || {
        error "GATEKEEPER PACKAGE TEST FAILED!";
        return 1;
    }
}

function delete_workload_cluster {
    echo "Deleting workload cluster"
    time tanzu cluster delete ${WORKLOAD_CLUSTER_NAME} -y || {
        error "WORKLOAD CLUSTER DELETION FAILED!"
        return 1
    }
}

function wait_for_workload_cluster_deletion {
    wait_iterations=120

    for (( i = 1 ; i <= wait_iterations ; i++ ))
    do
        echo "Waiting for workload cluster to get deleted..."
        num_of_clusters=$(tanzu cluster list -o json | jq 'length')
        if [[ "$num_of_clusters" == "0" ]]; then
            echo "Workload cluster ${WORKLOAD_CLUSTER_NAME} successfully deleted"
            break
        fi
        if [[ "${i}" == "${wait_iterations}" ]]; then
            echo "Timed out waiting for workload cluster ${WORKLOAD_CLUSTER_NAME} to get deleted"
            return 1
        fi
        sleep 5
    done
}

function wait_for_pods {
    kubectl config use-context "${CLUSTER_NAME}"-admin@"${CLUSTER_NAME}" || {
        error "CONTEXT SWITCH TO STANDALONE CLUSTER FAILED!";
        return 1;
    }
    kubectl wait --for=condition=ready pod --all --all-namespaces --timeout=900s || {
        error "TIMED OUT WAITING FOR ALL PODS TO BE UP!";
        return 1;
    }
}

function cleanup_standalone_cluster {
    kubeconfig_cleanup ${CLUSTER_NAME}
    azure_cluster_cleanup || {
        error "STANDLONE CLUSTER CLEANUP USING azure CLI FAILED! Please manually delete any ${CLUSTER_NAME} standalone cluster resources using Azure Web UI"
        return 1
    }
}

function delete_standalone_cluster_or_cleanup {
    echo "Deleting standalone cluster"
    time tanzu standalone-cluster delete ${CLUSTER_NAME} -y || {
        error "STANDALONE CLUSTER DELETION FAILED!";
        collect_standalone_cluster_diagnostics azure ${CLUSTER_NAME}
        delete_kind_cluster
        cleanup_standalone_cluster
        return 1
    }
}

function create_standalone_cluster {
    echo "Bootstrapping TCE standalone cluster on Azure..."
    time tanzu standalone-cluster create "${CLUSTER_NAME}" -f "${TCE_REPO_PATH}/test/azure/cluster-config.yaml" || {
        error "STANDALONE CLUSTER CREATION FAILED!";
        return 1;
    }
}
