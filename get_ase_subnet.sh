#!/bin/bash
# Exit if any of the intermediate steps fail
set -e
# Extract "ase_name" argument from the input into
# ASE_NAME shell variables.
#
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "ASE_NAME=\(.ase_name)"')"

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
AZURE_LOGIN=`
  az login --service-principal \
    --username $ARM_CLIENT_ID \
    --password $ARM_CLIENT_SECRET \
    --tenant $ARM_TENANT_ID

  az account set --subscription $ARM_SUBSCRIPTION_ID
  `
# AZURE_SET_ACCOUNT =`
#   az account set --subscription $ARM_SUBSCRIPTION_ID
#   `
ASE_VNET=`az appservice ase show \
  --name "$ASE_NAME" \
  --query vnetName \
  --output tsv
`
ASE_VNET_SUBNET=`az appservice ase show \
  --name "$ASE_NAME" \
  --query vnetSubnetName \
  --output tsv
`
ASE_VNET_RESOURCE_GROUP=`az appservice ase show \
  --name "$ASE_NAME" \
  --query vnetResourceGroupName \
  --output tsv
`
jq -n \
  --arg ase_vnet "$ASE_VNET" \
  --arg ase_vnet_subnet "$ASE_VNET_SUBNET" \
  --arg ase_vnet_resource_group "$ASE_VNET_RESOURCE_GROUP" \
  '{
     "ase_vnet":$ase_vnet,
     "ase_vnet_subnet":$ase_vnet_subnet,
     "ase_vnet_resource_group":$ase_vnet_resource_group
  }'
    
  
  

  
  
  
    
      
      