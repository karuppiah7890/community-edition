#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o xtrace
set -o pipefail
set -o nounset

TCE_REPO_PATH="$(git rev-parse --show-toplevel)"

# shellcheck source=test/util/utils.sh
source "${TCE_REPO_PATH}/test/util/utils.sh"
# shellcheck source=test/azure/utils.sh
source "${TCE_REPO_PATH}/test/azure/utils.sh"

"${TCE_REPO_PATH}/test/install-dependencies.sh" || { error "Dependency installation failed!"; exit 1; }
"${TCE_REPO_PATH}/test/build-tce.sh" || { error "TCE installation failed!"; exit 1; }

CLUSTER_NAME=uc-${RANDOM}

# create cluster

tanzu unmanaged-cluster create ${CLUSTER_NAME} || {
    error "Unmanaged Cluster Creation failed!";
    exit 1;
}

# list clusters

tanzu unmanaged-cluster list || {
    error "Unmanaged Cluster List failed!";
    exit 1;
}

tanzu unmanaged-cluster list | grep ${CLUSTER_NAME} || {
    error "Unmanaged Cluster List does not contain created cluster!";
    exit 1;
}

# check cluster creation

"${TCE_REPO_PATH}/test/check-tce-cluster-creation.sh" ${CLUSTER_NAME} || {
    error "Unmanaged Cluster Creation check failed!";
    exit 1;
}

# list packages

tanzu package available list || {
    error "Listing Packages failed!";
    exit 1;
}

# delete cluster

tanzu unmanaged-cluster delete ${CLUSTER_NAME} || {
    error "Unmanaged Cluster Deletion failed!";
    exit 1;
}
