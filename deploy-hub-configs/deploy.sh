#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -m

# variables
# #########
# uncomment it, change it or get it from gh-env vars (default behaviour: get from gh-env)
# export KUBECONFIG=/root/admin.kubeconfig

# Load common vars
source ${WORKDIR}/shared-utils/common.sh

echo ">>>> Preparing and replace info in the manifests"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

sed -i "s/CHANGEME/$OC_RHCOS_RELEASE/g" 04-agent-service-config.yml
HTTPSERVICE=$(oc get routes -n default | grep httpd-server-route | awk '{print $2}')
sed -i "s/HTTPD_SERVICE/$HTTPSERVICE/g" 04-agent-service-config.yml
pull=$(oc get secret -n openshift-config pull-secret -ojsonpath='{.data.\.dockerconfigjson}' | base64 -d)
sed -i "s/PULL_SECRET/$pull/g" 05-pullsecrethub.yml
LOCAL_REG=$(oc get route -n openshift-image-registry | awk '{print $2}' | tail -1)
sed -i "s/CHANGEDOMAIN/$LOCAL_REG/g" registryconf.txt
CABUNDLE=$(oc get cm -n openshift-image-registry kube-root-ca.crt --template='{{index .data "ca.crt"}}')
echo -e "  ca-bundle.crt: |\n$(echo -n "$CABUNDLE" | sed "s/^/    /")" >>01_Mirror_ConfigMap.yml
cat registryconf.txt >>01_Mirror_ConfigMap.yml
NEWTAG=$LOCAL_REG/ocp4/openshift4:$OC_OCP_TAG
sed -i "s%TAG_OCP_IMAGE_RELEASE%$NEWTAG%g" 02-cluster_imageset.yml

echo ">>>> Deploy hub configs"
echo ">>>>>>>>>>>>>>>>>>>>>>>"

oc create -f 01_Mirror_ConfigMap.yml
oc create -f 02-cluster_imageset.yml
oc create -f 03-configmap.yml
oc create -f 04-agent-service-config.yml
oc create -f 05-pullsecrethub.yml

oc patch hiveconfig hive --type merge -p '{"spec":{"targetNamespace":"hive","logLevel":"debug","featureGates":{"custom":{"enabled":["AlphaAgentInstallStrategy"]},"featureSet":"Custom"}}}'

echo ">>>> Wait for ACM and AI deployed successfully"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
while [[ $(oc get pod -n open-cluster-management | grep assisted | wc -l) -eq 0 ]]; do
	echo "Waiting for Assisted installer to be ready..."
	sleep 5
done
../"$SHARED_DIR"/wait_for_deployment.sh -t 1000 -n open-cluster-management assisted-service

echo ">>>>EOF"
echo ">>>>>>>"
