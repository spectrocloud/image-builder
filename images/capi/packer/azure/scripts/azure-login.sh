#!/bin/bash
#echo "client_id: ${AZURE_CLIENT_ID} client_secret:${AZURE_CLIENT_SECRET} tenant_id:${AZURE_TENANT_ID} subscription_id: ${AZURE_SUBSCRIPTION_ID}"
az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "failed to login into azure account"
  exit 1
fi
az account set -s ${AZURE_SUBSCRIPTION_ID} > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "failed to set account with subscription"
  exit 1
fi

export RESOURCE_GROUP_NAME=`cat packer/azure/azure-config.json | jq -r '.azure_resource_group'`
export AZURE_LOCATION=`cat packer/azure/azure-config.json | jq -r '.azure_location'`
if [[ ! -z "${RESOURCE_GROUP_NAME}" ]]
then
   az group show -n ${RESOURCE_GROUP_NAME} > /dev/null 2>&1
   if [ $? -ne 0 ]
   then
     echo "create resource group : $RESOURCE_GROUP_NAME"
     az group create -n ${RESOURCE_GROUP_NAME} -l ${AZURE_LOCATION} > /dev/null 2>&1
     if [ $? -ne 0 ]
     then
       echo "failed to create resource group $RESOURCE_GROUP_NAME"
       exit 1
     fi
     echo "resource group $RESOURCE_GROUP_NAME created"
   else
     echo "resource group $RESOURCE_GROUP_NAME already present"
   fi
fi

export STORAGE_ACCOUNT_NAME=`cat packer/azure/azure-config.json | jq -r '.storage_account_name'`
if [[ ! -z "${STORAGE_ACCOUNT_NAME}" ]]
then
  az storage account show -g ${RESOURCE_GROUP_NAME} -n ${STORAGE_ACCOUNT_NAME} > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "create storage account : $STORAGE_ACCOUNT_NAME"
    az storage account create -n ${STORAGE_ACCOUNT_NAME} -g ${RESOURCE_GROUP_NAME} > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
      echo "failed to create storage account $STORAGE_ACCOUNT_NAME"
      exit 1
    fi
    echo "storage account: $STORAGE_ACCOUNT_NAME created"
  else
    echo "storage account: $STORAGE_ACCOUNT_NAME already present"
  fi
fi
