variable "location" {
  description = "Azure region"
  type        = string
  default     = "southindia"
}

variable "resource_group" {
  description = "Resource group"
  type        = string
  default     = "calmccrg"
}


variable "storage_account" {
  description = "Storage Account"
  type = string
  default = "calmccsa"
}

variable "blob_store" {
  description = "Blob Storage"
  type = string
  default = "calmccblobstore"
}

variable "service_plan" {
  description = "Service Plan"
  type = string
  default = "calmccserviceplan"
}

variable "blob_storage_container" {
  description = "Blob Storage Container Name"
  type = string
  default = "calmccblobstore"
}

locals {
  function_zip_timestamp = formatdate("YYYYMMDD_hhmmss", timestamp())
  function_zip_name      = "function_${local.function_zip_timestamp}.zip"
}


############################################
# Terraform Backend (State Storage)
############################################
terraform {
  backend "azurerm" {
    resource_group_name  = "calmccrg"
    storage_account_name = "calmccsa"
    container_name       = "calmcctfstate"
    key                  = "calmcctfstate/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "3bf3e411-8098-44b9-b34f-73b2829eb2ad"
  tenant_id       = "6f753707-3acb-427a-8c54-ae9256022fbb"
}

############################################
# Use Existing Storage Account for Function
############################################
data "azurerm_storage_account" "sa" {
  name                = var.storage_account
  resource_group_name = var.resource_group
}

############################################
# Use Existing Service Plan (Linux, B1)
############################################
data "azurerm_service_plan" "plan" {
  name                = var.service_plan
  resource_group_name = var.resource_group
}


############################################
# Build ZIP locally (Git Bash)
############################################
resource "null_resource" "build_function" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<EOT
      pushd azure-function-ts
      chmod +x build.sh
      ./build.sh
      popd
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

############################################
# Upload ZIP to Blob Storage (Timestamped)
############################################
resource "azurerm_storage_blob" "function_zip" {
  name                   = local.function_zip_name
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = var.blob_storage_container
  type                   = "Block"
  source                 = "${path.module}/azure-function-ts/function.zip"

  depends_on = [null_resource.build_function]
}


############################################
# Generate SAS Token for ZIP
############################################
data "azurerm_storage_account_sas" "sas" {
  connection_string = data.azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  start             = "2024-01-01"
  expiry            = "2030-01-01"

  resource_types {
    object    = true
    service   = false
    container = false
  }

  services {
    blob  = true
    file  = false
    table = false
    queue = false
  }

  permissions {
    read   = true
    list   = false
    add    = false
    create = false
    write  = false
    update = false
    delete = false
    process = false
    filter = false
    tag    = false
  }
}


############################################
# Random suffix for unique Function App name
############################################
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

############################################
# Function App (Linux + Node16 + V3)
############################################
resource "azurerm_linux_function_app" "func" {
  name                = "calmccfnappv3-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group
  service_plan_id     = data.azurerm_service_plan.plan.id

  storage_account_name       = data.azurerm_storage_account.sa.name
  storage_account_access_key = data.azurerm_storage_account.sa.primary_access_key

  site_config {
    always_on = true
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    WEBSITE_RUN_FROM_PACKAGE       = "https://${data.azurerm_storage_account.sa.name}.blob.core.windows.net/${var.blob_store}/${local.function_zip_name}?${data.azurerm_storage_account_sas.sas.sas}"
    WEBSITE_NODE_DEFAULT_VERSION   = "~18"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    FUNCTIONS_EXTENSION_VERSION  = "~3"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_storage_blob.function_zip]
}
