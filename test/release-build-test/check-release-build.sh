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

TCE_DARWIN_TAR_BALL="${TCE_REPO_PATH}/tce-darwin-amd64-${version}.tar.gz"
TCE_DARWIN_INSTALLATION_DIR="${TCE_REPO_PATH}/tce-darwin-amd64-${version}"
SECURITY_ISSUE_POPUP_COUNT_FILE="${TCE_REPO_PATH}/tce-security-issue-popup-count"

# "${TCE_REPO_PATH}"/hack/get-tce-release.sh  darwin

# Download TCE tar ball using Chrome / Chromium browser and using Chrome DevTools Protocol.
# This is because - when TCE tar ball is downloaded using curl - tar balls containing binaries that are
# not properly signed are also considered valid and the installation succeeds leading to a false test result.
# go run download-release-build.go \
#     -tce-tarball-link https://github.com/vmware-tanzu/community-edition/releases/download/"${version}"/tce-darwin-amd64-"${version}".tar.gz

pushd "${TCE_REPO_PATH}"/test/release-build-test

go run download-release-build.go \
    -tce-tarball-link https://github.com/karuppiah7890/community-edition/releases/download/"${version}"/tce-darwin-amd64-"${version}".tar.gz \
    -tce-tarball-path "${TCE_DARWIN_TAR_BALL}"

popd

tar xvzf "${TCE_DARWIN_TAR_BALL}"

function run_script_to_close_security_issue_popups() {
    osascript "${TCE_REPO_PATH}"/test/release-build-test/close-security-issue-popups.applescript ${SECURITY_ISSUE_POPUP_COUNT_FILE} &
    applescript_pid=$!
    return $applescript_pid
}

function check_security_issue_popups() {
    if [ ! -f ${SECURITY_ISSUE_POPUP_COUNT_FILE} ]; then
        return 0
    fi

    SECURITY_ISSUE_POPUP_COUNT=$(cat ${SECURITY_ISSUE_POPUP_COUNT_FILE})

    if [ ${SECURITY_ISSUE_POPUP_COUNT} != 0 ]; then
        echo "There were ${SECURITY_ISSUE_POPUP_COUNT} security issue popups"
        return 1
    fi
}

applescript_pid=$(run_script_to_close_security_issue_popups)

"${TCE_DARWIN_INSTALLATION_DIR}"/install.sh

kill -9 $applescript_pid

check_security_issue_popups


applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu cluster version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu conformance version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu diagnostics version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu kubernetes-release version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu management-cluster version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu package version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu standalone-cluster version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu pinniped-auth version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu builder version

kill -9 $applescript_pid

check_security_issue_popups

applescript_pid=$(run_script_to_close_security_issue_popups)

tanzu login version

kill -9 $applescript_pid

check_security_issue_popups
