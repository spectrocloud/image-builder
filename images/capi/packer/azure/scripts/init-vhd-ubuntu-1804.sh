#!/bin/bash
client_id=`cat ../azure-config.json | jq '.client_id'`
client_secret=`cat ../azure-config.json | jq '.client_secret'`
tenant_id=`cat ../azure-config.json | jq '.azure_tenant_id'`
subscription_id=`cat ../azure-config.json | jq '.subscription_id'`
#az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
az login --service-principal -u $client_id -p $client_secret --tenant $tenant_id
az account set -s $subscription_id
#export RESOURCE_GROUP_NAME=cluster-api-images
#export AZURE_LOCATION="${AZURE_LOCATION:-southcentralus}"
az group create -n $5 -l $6
echo "resource group name: $5"
#CREATE_TIME="$(date +%s)"
#export STORAGE_ACCOUNT_NAME="spectro${CREATE_TIME}"
az storage account create -n $7 -g $5
echo "storage name: $7"
