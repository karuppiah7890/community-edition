#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

GITHUB_REF="${1:?GitHub Reference argument empty. Example usage: ./hack/homebrew/update-homebrew-package.sh refs/tags/v0.10.0}"
: ${GITHUB_TOKEN:?GITHUB_TOKEN is not set}

version=${GITHUB_REF/refs\/tags\//}

temp_dir=$(mktemp -d)

pushd "${temp_dir}"

wget https://github.com/karuppiah7890/community-edition/releases/download/"${version}"/tce-checksums.txt

darwin_amd64_shasum=$(grep tce-darwin-amd64-"${version}".tar.gz tce-checksums.txt | cut -d ' ' -f 1)

linux_amd64_shasum=$(grep tce-linux-amd64-"${version}".tar.gz tce-checksums.txt | cut -d ' ' -f 1)

# git clone https://github.com/vmware-tanzu/homebrew-tanzu
git clone https://github.com/karuppiah7890/homebrew-tanzu

cd homebrew-tanzu

# make sure we are on main branch before checking out
git checkout main

PR_BRANCH="update-tce-to-${version}-${RANDOM}"

# Random number in branch name in case there's already some branch for the version update,
# though there shouldn't be one. There could be one if the other branch's PR tests failed and didn't merge
git checkout -b "${PR_BRANCH}"

# Replacing old version with the latest stable released version.
# Using -i so that it works on Mac and Linux OS, so that it's useful for local development.
sed -i.bak "s/version \"v.*/version \"${version}\"/" tanzu-community-edition.rb
rm -fv tanzu-community-edition.rb.bak

# First occurence of sha256 is for MacOS SHA sum
awk "/sha256 \".*/{c+=1}{if(c==1){sub(\"sha256 \\\".*\",\"sha256 \\\"${darwin_amd64_shasum}\\\"\",\$0)};print}" tanzu-community-edition.rb > tanzu-community-edition-updated.rb
mv tanzu-community-edition-updated.rb tanzu-community-edition.rb

# Second occurence of sha256 is for Linux SHA sum
awk "/sha256 \".*/{c+=1}{if(c==2){sub(\"sha256 \\\".*\",\"sha256 \\\"${linux_amd64_shasum}\\\"\",\$0)};print}" tanzu-community-edition.rb > tanzu-community-edition-updated.rb
mv tanzu-community-edition-updated.rb tanzu-community-edition.rb

git add tanzu-community-edition.rb

git commit -m "auto-generated - update tce homebrew formula for version ${version}"

git push origin "${PR_BRANCH}"

gh pr create --repo karuppiah7890/homebrew-tanzu --title "auto-generated - update tce homebrew formula for version ${version}" --body "auto-generated - update tce homebrew formula for version ${version}"

gh pr merge --repo karuppiah7890/homebrew-tanzu "${PR_BRANCH}" --squash --delete-branch

popd
