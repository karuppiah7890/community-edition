#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

version="${1:?TCE version argument empty. Example usage: ./test/release-build-test/check-release-build.sh v0.10.0}"

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# There's an extra /.. here as this is inside linux directory
TCE_REPO_PATH="${MY_DIR}"/../../..

# TODO: Make the script generic and make it work for both Linux and Mac. Find OS like this -
# BUILD_OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# if [[ "$BUILD_OS" != "linux" ]] && [[ "$BUILD_OS" != "darwin" ]]; then
#     error "Installation on $BUILD_OS is not supported."
#     exit 1
# fi

TCE_RELEASE_TAR_BALL="${TCE_REPO_PATH}/tce-linux-amd64-${version}.tar.gz"
TCE_INSTALLATION_DIR="${TCE_REPO_PATH}/tce-linux-amd64-${version}"

# TODO: Make the script generic and make it work for both Linux and Mac. For Mac, we have to download the tar ball
# from a browser - Chrome, Firefox etc. The Golang code can download from Chrome
# pushd "${TCE_REPO_PATH}"/test/release-build-test

# # Download TCE tar ball using Chrome / Chromium browser and using Chrome DevTools Protocol.
# # This is because - when TCE tar ball is downloaded using curl - tar balls containing binaries that are
# # not properly signed are also considered valid and the installation succeeds leading to a false test result.
# go run download-release-build.go \
#     -tce-tarball-link https://github.com/vmware-tanzu/community-edition/releases/download/"${version}"/tce-darwin-amd64-"${version}".tar.gz \
#     -tce-tarball-path "${TCE_RELEASE_TAR_BALL}"

# popd

# TODO: Change to main repo link later for PR
# wget "https://github.com/vmware-tanzu/community-edition/releases/download/${version}/tce-linux-amd64-${version}.tar.gz"
wget "https://github.com/karuppiah7890/community-edition/releases/download/${version}/tce-linux-amd64-${version}.tar.gz" -P "${TCE_REPO_PATH}"

tar xvzf "${TCE_RELEASE_TAR_BALL}" --directory "${TCE_REPO_PATH}"

# TODO: Make the script generic and make it work for both Linux and Mac. Only for Mac, we might have to do some
# Mac specific stuff for signing issues
# osascript "${TCE_REPO_PATH}"/test/release-build-test/close-security-issue-popups.applescript &
# applescript_pid=$!
# trap '{ kill $applescript_pid ; }' EXIT

"${TCE_INSTALLATION_DIR}"/install.sh

tanzu version

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
