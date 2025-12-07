@echo off
REM ================================================
REM  Azure Infrastructure Bootstrap Script (Windows)
REM  - Creates Resource Group
REM  - Creates Storage Account
REM  - Creates Blob Containers (TF State + App ZIPs)
REM  - Creates Linux App Service Plan
REM ================================================

REM -----------------------------------------------
REM 1️⃣ Verify Azure Login & Subscription
REM -----------------------------------------------
REM Login if not already authenticated
REM az login

REM List available subscriptions
az account list --output table

REM -----------------------------------------------
REM 2️⃣ Configuration Variables
REM -----------------------------------------------
set LOCATION=southindia
set RESOURCE_GROUP=calmccrg
set STORAGE_ACCOUNT=calmccsa
set TF_STATE_STORE=calmcctfstate
set BLOB_STORE=calmccblobstore
set SERVICE_PLAN=calmccserviceplan

REM -----------------------------------------------
REM 3️⃣ Create Resource Group
REM -----------------------------------------------
echo Creating Resource Group...
az group create ^
  --name %RESOURCE_GROUP% ^
  --location %LOCATION%

REM -----------------------------------------------
REM 4️⃣ Create Storage Account
REM -----------------------------------------------
echo Creating Storage Account...
az storage account create ^
  --name %STORAGE_ACCOUNT% ^
  --resource-group %RESOURCE_GROUP% ^
  --location %LOCATION% ^
  --sku Standard_LRS

REM -----------------------------------------------
REM 5️⃣ Fetch Storage Account Access Key
REM -----------------------------------------------
echo Fetching Storage Account Key...
FOR /F "tokens=*" %%i IN ('az storage account keys list --resource-group %RESOURCE_GROUP% --account-name %STORAGE_ACCOUNT% --query [0].value -o tsv') DO (
  set ACCOUNT_KEY=%%i
)

REM -----------------------------------------------
REM 6️⃣ Create Blob Containers
REM -----------------------------------------------

REM Terraform State Container
echo Creating Terraform state container...
az storage container create ^
  --name %TF_STATE_STORE% ^
  --account-name %STORAGE_ACCOUNT% ^
  --account-key %ACCOUNT_KEY%

REM Application Artifact Container
echo Creating application artifact container...
az storage container create ^
  --name %BLOB_STORE% ^
  --account-name %STORAGE_ACCOUNT% ^
  --account-key %ACCOUNT_KEY%

REM -----------------------------------------------
REM 7️⃣ Create Linux App Service Plan
REM -----------------------------------------------
echo Creating Linux App Service Plan...
az appservice plan create ^
  --name %SERVICE_PLAN% ^
  --resource-group %RESOURCE_GROUP% ^
  --location %LOCATION% ^
  --sku B1 ^
  --is-linux

REM -----------------------------------------------
REM ✅ Completed
REM -----------------------------------------------
echo ✅ Azure infrastructure setup completed successfully.
pause
