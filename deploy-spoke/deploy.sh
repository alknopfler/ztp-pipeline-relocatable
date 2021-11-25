#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -m

# variables
# #########
# uncomment it, change it or get it from gh-env vars (default behaviour: get from gh-env)
# export KUBECONFIG=/root/admin.kubeconfig

echo ">>>> Deploy all the manifests using kustomize"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

# Load common vars
source ${WORKDIR}/shared-utils/common.sh

cd ${OUTPUTDIR}
oc apply -k .

echo ">>>>EOF"
echo ">>>>>>>"
