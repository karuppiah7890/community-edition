#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

version="${1:?TCE version argument empty. Example usage: ./test/release-build-test/check-release-build.sh v0.10.0}"

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TCE_REPO_PATH="${MY_DIR}"/../..

TCE_DARWIN_TAR_BALL="tce-darwin-amd64-${version}.tar.gz"
TCE_DARWIN_INSTALLATION_DIR="tce-darwin-amd64-${version}"

# "${TCE_REPO_PATH}"/hack/get-tce-release.sh  darwin

# Download TCE tar ball using Chrome / Chromium browser and using Chrome DevTools Protocol.
# This is because - when TCE tar ball is downloaded using curl - tar balls containing binaries that are
# not properly signed are also considered valid and the installation succeeds leading to a false test result.
# go run download-release-build.go \
#     -tce-tarball-link https://github.com/vmware-tanzu/community-edition/releases/download/"${version}"/tce-darwin-amd64-"${version}".tar.gz
go run download-release-build.go \
    -tce-tarball-link https://github.com/karuppiah7890/community-edition/releases/download/"${version}"/tce-darwin-amd64-"${version}".tar.gz

tar xvzf ${TCE_DARWIN_TAR_BALL}

./"${TCE_DARWIN_INSTALLATION_DIR}"/install.sh

tanzu cluster version

tanzu conformance version

tanzu diagnostics version

tanzu kubernetes-release version

tanzu management-cluster version

tanzu package version

tanzu standalone-cluster version

tanzu pinniped-auth version

tanzu builder version

tanzu login version
