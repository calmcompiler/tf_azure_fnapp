#!/bin/bash
############################################
# Azure Infrastructure Bootstrap Script
# - Creates Resource Group
# - Creates Storage Account
# - Creates Blob Containers (TF State + App Packages)
# - Creates Linux App Service Plan
############################################

# ------------------------------------------
# 1️⃣ Login & Verify Subscription
# ------------------------------------------
# Login to Azure (only required once per session)
# az login

# List available Azure subscriptions
az account list --output table

# ------------------------------------------
# 2️⃣ Configuration Variables
# ------------------------------------------
LOCATION="southindia"                 # Azure region
RESOURCE_GROUP="calmccrg"             # Resource Group name
STORAGE_ACCOUNT="calmccsa"            # Storage Account for TF state & app packages
TF_STATE_STORE="calmcctfstate"        # Blob container for Terraform state
BLOB_STORE="calmccblobstore"          # Blob container for application ZIP artifacts
SERVICE_PLAN="calmccserviceplan"     # App Service Plan name

# ------------------------------------------
# 3️⃣ Create Resource Group
# ------------------------------------------
echo "Creating Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# ------------------------------------------
# 4️⃣ Create Storage Account
# ------------------------------------------
echo "Creating Storage Account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# ------------------------------------------
# 5️⃣ Fetch Storage Account Access Key
# ------------------------------------------
echo "Fetching Storage Account Key..."
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query [0].value \
  -o tsv)

# ------------------------------------------
# 6️⃣ Create Blob Containers
# ------------------------------------------

# Container for Terraform remote state
echo "Creating Terraform state container..."
az storage container create \
  --name $TF_STATE_STORE \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

# Container for Application ZIP deployments
echo "Creating application artifact container..."
az storage container create \
  --name $BLOB_STORE \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

# ------------------------------------------
# 7️⃣ Create Linux App Service Plan
# ------------------------------------------
echo "Creating Linux App Service Plan..."
az appservice plan create \
  --name $SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku B1 \
  --is-linux

# ------------------------------------------
# ✅ Completed
# ------------------------------------------
echo "✅ Azure infrastructure setup completed successfully."
