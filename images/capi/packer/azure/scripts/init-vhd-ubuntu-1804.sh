#!/bin/bash

#az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
az login --service-principal -u $1 -p $2 --tenant $3
az account set -s $4
#export RESOURCE_GROUP_NAME=cluster-api-images
#export AZURE_LOCATION="${AZURE_LOCATION:-southcentralus}"
az group create -n $5 -l $6
echo "resource group name: $5"
#CREATE_TIME="$(date +%s)"
#export STORAGE_ACCOUNT_NAME="spectro${CREATE_TIME}"
az storage account create -n $7 -g $5
echo "storage name: $7"
