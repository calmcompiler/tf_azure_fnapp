#az login
az account list --output table

LOCATION=southindia
RESOURCE_GROUP=calmccrg
STORAGE_ACCOUNT=calmccsa
TF_STATE_STORE=calmcctfstate
BLOB_STORE=calmccblobstore
SERVICE_PLAN=calmccserviceplan

az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS

ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query [0].value -o tsv)

az storage container create --name $TF_STATE_STORE --account-name $STORAGE_ACCOUNT --account-key $ACCOUNT_KEY

az storage container create --name $BLOB_STORE --account-name $STORAGE_ACCOUNT --account-key $ACCOUNT_KEY

az appservice plan create --name $SERVICE_PLAN --resource-group $RESOURCE_GROUP --location $LOCATION --sku B1 --is-linux
