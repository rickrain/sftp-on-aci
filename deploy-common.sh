#!/bin/bash -e

# Create the common resource group
echo "Creating common infrastructure resource group '$COMMON_RG_NAME' in region '$COMMON_LOCATION'."
az group create --name $COMMON_RG_NAME --location $COMMON_LOCATION --output none

# Create managed identity
echo "Creating user-assigned managed identity '$MI_ID_NAME'."
MI_ID=$(az identity create --resource-group $COMMON_RG_NAME --name $MI_ID_NAME --query principalId --output tsv)
MI_RESOURCE_ID=$(az resource show --resource-group $COMMON_RG_NAME --name $MI_ID_NAME --resource-type "Microsoft.ManagedIdentity/userAssignedIdentities" --query id --output tsv)

# Create key vault and assign access policy for managed identity
echo "Creating key vault '$KV_NAME'."
KV_RESOURCE_ID=$(az keyvault create --name $KV_NAME --resource-group $COMMON_RG_NAME --location $COMMON_LOCATION --query id --output tsv)
ROLE_NAME="Key Vault Secrets User"
echo "Assigning role '$ROLE_NAME' to managed identity '$MI_ID_NAME' scoped to Key Vaule '$KV_NAME'."
az role assignment create --role $ROLE_NAME --assignee-object-id $MI_ID --assignee-principal-type ServicePrincipal --scope $KV_RESOURCE_ID --output none
echo "Setting key vault policy (get/list secrets) for '$MI_ID_NAME'."
az keyvault set-policy --name $KV_NAME --object-id $MI_ID --secret-permissions get list --output none

# Create storage account and upload the 'deploy-helper.sh' script
SHARE_NAME="setup"
HELPER_SCRIPT_LOCAL="./deploy-helper.sh"

echo "Creating storage account '$STG_ACCT_NAME'."
az storage account create --resource-group $COMMON_RG_NAME --name $STG_ACCT_NAME --sku PREMIUM_LRS --kind FileStorage --output none
STG_CONN_STRING=$(az storage account show-connection-string --name $STG_ACCT_NAME --output tsv)

echo "Creating file share"
az storage share create --name $SHARE_NAME --connection-string $STG_CONN_STRING --output none

echo "Uploading helper script"
az storage file upload --share-name $SHARE_NAME --source $HELPER_SCRIPT_LOCAL --connection-string $STG_CONN_STRING --output none

echo ""
echo "Common resources have been successfully provisioned and configured."
echo ""
