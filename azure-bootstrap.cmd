@echo off
setlocal

REM ================================================
REM  Azure Infrastructure Bootstrap Script (Windows)
REM ================================================

echo Running azure-bootstrap.cmd ...

REM -----------------------------------------------
REM Configuration Variables
REM -----------------------------------------------
set LOCATION=southindia
set RESOURCE_GROUP=calmccrg
set STORAGE_ACCOUNT=calmccsa
set TF_STATE_STORE=calmcctfstate
set BLOB_STORE=calmccblobstore
set SERVICE_PLAN=calmccserviceplan

echo Using:
echo   LOCATION        = %LOCATION%
echo   RESOURCE_GROUP  = %RESOURCE_GROUP%
echo   STORAGE_ACCOUNT = %STORAGE_ACCOUNT%
echo   TF_STATE_STORE  = %TF_STATE_STORE%
echo   BLOB_STORE      = %BLOB_STORE%
echo   SERVICE_PLAN    = %SERVICE_PLAN%
echo.

REM -----------------------------------------------
REM Create Resource Group
REM -----------------------------------------------
echo [STEP] Creating Resource Group...
call az group create --name "%RESOURCE_GROUP%" --location "%LOCATION%"
echo.

REM -----------------------------------------------
REM Create Storage Account
REM -----------------------------------------------
echo [STEP] Creating Storage Account...
call az storage account create --name "%STORAGE_ACCOUNT%" --resource-group "%RESOURCE_GROUP%" --location "%LOCATION%" --sku Standard_LRS
echo.

REM -----------------------------------------------
REM Fetch Storage Account Key
REM -----------------------------------------------
echo [STEP] Fetching Storage Account Key...

FOR /F "delims=" %%i IN ('az storage account keys list --resource-group "%RESOURCE_GROUP%" --account-name "%STORAGE_ACCOUNT%" --query [0].value -o tsv') DO (
  set "ACCOUNT_KEY=%%i"
)

echo Retrieved ACCOUNT_KEY=%ACCOUNT_KEY%
echo.

REM -----------------------------------------------
REM Create Blob Containers
REM -----------------------------------------------
echo [STEP] Creating Terraform state container...
call az storage container create --name "%TF_STATE_STORE%" --account-name "%STORAGE_ACCOUNT%" --account-key "%ACCOUNT_KEY%"
echo.

echo [STEP] Creating application artifact container...
call az storage container create --name "%BLOB_STORE%" --account-name "%STORAGE_ACCOUNT%" --account-key "%ACCOUNT_KEY%"
echo.

REM -----------------------------------------------
REM Create Linux App Service Plan
REM -----------------------------------------------
echo [STEP] Creating Linux App Service Plan...
REM call az appservice plan create --name "%SERVICE_PLAN%" --resource-group "%RESOURCE_GROUP%" --location "%LOCATION%" --sku B1 --is-linux
echo.

REM -----------------------------------------------
REM Completed
REM -----------------------------------------------
echo Azure infrastructure setup completed successfully.

endlocal
