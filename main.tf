variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
  default     = "southindia"
}

variable "resource_group" {
  description = "Resource group"
  type = string
  default = "calmccrg"
}

##################################################################################

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

##################################################################################

data "azurerm_storage_account" "sa" {
  name                = "calmccsa"
  resource_group_name = var.resource_group
}


resource "azurerm_service_plan" "plan" {
  name                = "calmccserviceplan"
  location            = var.location
  resource_group_name = var.resource_group
  sku_name = "B1"
  os_type  = "Linux"
}


resource "null_resource" "build_function" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]  # forces Bash interpreter
    command = <<EOT
      cd azure-function-ts
      ./build.sh
      unzip -l function.zip
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}


resource "azurerm_storage_blob" "function_zip" {
  name                   = "function.zip"
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = "calmccblobstore"
  type                   = "Block"
  source                 = "azure-function-ts/function.zip"

  depends_on = [
    null_resource.build_function
  ]

  lifecycle {
    replace_triggered_by = [
      null_resource.build_function
    ]
  }

}


data "azurerm_storage_account_sas" "sas" {
  connection_string = data.azurerm_storage_account.sa.primary_connection_string

  https_only = true
  start      = "2024-01-01"
  expiry     = "2030-01-01"

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}


##################################################################################

resource "azurerm_linux_function_app" "func" {
  name                = "calmccfnapp-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group
  service_plan_id     = azurerm_service_plan.plan.id

  storage_account_name       = data.azurerm_storage_account.sa.name
  storage_account_access_key = data.azurerm_storage_account_sas.sas.sas

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "node"
    FUNCTIONS_EXTENSION_VERSION   = "~4"
    WEBSITE_RUN_FROM_PACKAGE       = "https://${data.azurerm_storage_account.sa.name}.blob.core.windows.net/calmccblobstore/${azurerm_storage_blob.function_zip.name}${data.azurerm_storage_account_sas.sas.sas}"
    NODE_VERSION                   = "~20"    # Node 20 LTS
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
  }

  site_config {
    always_on = true
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_storage_blob.function_zip
  ]
}

#resource "azurerm_api_management" "apim" {
#  name                = "calmcc-apim-${random_string.suffix.result}"
#  location            = var.location
#  resource_group_name = var.resource_group
#  publisher_name      = "YourCompany"
#  publisher_email     = "admin@yourcompany.com"
#  sku_name            = "Developer_1"
#}


#resource "azurerm_api_management_api" "func_api" {
#  depends_on = [
#    azurerm_linux_function_app.func
#  ]
#
#  name                = "calmccfn-api"
#  resource_group_name = var.resource_group
#  api_management_name = azurerm_api_management.apim.name
#  revision            = "1"
#  display_name        = "Function API"
#  path                = "function"
#  protocols            = ["https"]
#
#  import {
#    content_format = "swagger-link-json"
#    content_value = jsonencode({
#      openapi = "3.0.1"
#      info = {
#        title   = "Function API"
#        version = "1.0.0"
#      }
#      paths = {
#        "/hello1" = {
#          get = {
#            responses = { "200" = { description = "Hello1 response" } }
#            "x-azure-settings" = { backend = { url = "https://${azurerm_linux_function_app.func.default_hostname}/api/hello1" } }
#          }
#        }
#        "/hello2" = {
#          get = {
#            responses = { "200" = { description = "Hello2 response" } }
#            "x-azure-settings" = { backend = { url = "https://${azurerm_linux_function_app.func.default_hostname}/api/hello2" } }
#          }
#        }
#        "/hello3" = {
#          get = {
#            responses = { "200" = { description = "Hello3 response" } }
#            "x-azure-settings" = { backend = { url = "https://${azurerm_linux_function_app.func.default_hostname}/api/hello3" } }
#          }
#        }
#      }
#    })
#  }
#}

