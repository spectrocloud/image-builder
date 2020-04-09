#!/bin/bash
echo "client_id: ${AZURE_CLIENT_ID} client_secret:${AZURE_CLIENT_SECRET} tenant_id:${AZURE_TENANT_ID} subscription_id: ${AZURE_SUBSCRIPTION_ID}"
az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
az account set -s ${AZURE_SUBSCRIPTION_ID}
export RESOURCE_GROUP_NAME=`cat packer/azure/azure-config.json | jq -r '.azure_resource_group'`
export AZURE_LOCATION=`cat packer/azure/azure-config.json | jq -r '.azure_location'`
#az group create -n $5 -l $6
echo "resource group name: $RESOURCE_GROUP_NAME"
#CREATE_TIME="$(date +%s)"
export STORAGE_ACCOUNT_NAME=`cat packer/azure/azure-config.json | jq -r '.storage_account_name'`
#az storage account create -n $7 -g $5
echo "storage name: $STORAGE_ACCOUNT_NAME"
