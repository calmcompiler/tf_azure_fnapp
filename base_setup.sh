#az login
#az account list --output table

az group create \
  --name calmccrg \
  --location southindia

az storage account create \
  --name calmccsa \
  --resource-group calmccrg \
  --location southindia \
  --sku Standard_LRS

ACCOUNT_KEY=$(az storage account keys list \
  --resource-group calmccrg \
  --account-name calmccsa \
  --query [0].value -o tsv)

az storage container create \
  --name calmcctfstate \
  --account-name calmccsa \
  --account-key $ACCOUNT_KEY

az storage container create \
  --name calmccblobstore \
  --account-name calmccsa \
  --account-key $ACCOUNT_KEY

