data azurerm_subnet "subnet" {
  count                = var.vnet_integration_enabled ? 1 : 0
  resource_group_name  = var.subnet.virtual_network_resource_group_name
  virtual_network_name = var.subnet.virtual_network_name
  name                 = var.subnet.virtual_network_subnet_name
}

data "azurerm_app_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  resource_group_name = var.app_service_plan_resource_group_name
}

data "azurerm_container_registry" "registry" {
  name                = var.registry_name 
  resource_group_name = var.registry_resource_group 
}

locals {
  domain    = title(var.info.domain)
  subdomain = title(var.info.subdomain)

  subproject = "${local.domain}${local.subdomain}"

  tags = merge(
    {
      for key, value in var.tags: key => title(value)
    }, 
    {
      subproject  = local.subproject
      environment = title(var.info.environment)
    }
  )

}

module naming {
  source  = "github.com/Azure/terraform-azurerm-naming?ref=64b9489"

  suffix  = [local.subproject]
}

module storage_account {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.storage-account?ref=v2.1.1"

  info = var.info
  tags = var.tags

  resource_group = var.resource_group_name
  location       = var.location

  default_action = "Allow"
  subresource_names        = var.subresource_names_storage
  private_endpoint_subnet  = var.private_endpoint_subnet
  private_endpoint_enabled = (
    contains(var.private_endpoint_resources_enabled, "file") ||
    contains(var.private_endpoint_resources_enabled, "blob") ||
    contains(var.private_endpoint_resources_enabled, "table") ||
    contains(var.private_endpoint_resources_enabled, "queue") ||
    contains(var.private_endpoint_resources_enabled, "web") ? true : false
  )
}

module private_endpoint {
  count = contains(var.private_endpoint_resources_enabled, "sites") ? 1 : 0

  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.private-endpoint?ref=v0.0.6"

  info = var.info
  tags = local.tags

  resource_group_name = var.resource_group_name
  location            = var.location

  resource_id       = azurerm_function_app.function_app.id
  subresource_names = ["sites"]

  private_endpoint_subnet = var.private_endpoint_subnet
}

resource "azurerm_function_app" "function_app" {
  name                       = replace(
    format("%s%s%03d",
      substr(
        module.naming.function_app.name, 0, 
        module.naming.function_app.max_length - 4
      ),
      substr(title(var.info.environment), 0, 1),
      title(var.info.sequence)
    ), "func-", "fn"
  )
  
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = data.azurerm_app_service_plan.app_service_plan.id
  storage_account_name       = module.storage_account.name
  storage_account_access_key = module.storage_account.access_key
  https_only                 = var.https_only
  os_type                    = var.os_type
  enable_builtin_logging     = var.enable_builtin_logging
  version                    = var.function_version
  app_settings               = var.app_settings


  tags = local.tags

  identity { 
    type = "SystemAssigned" 
  }

  site_config {
    
    always_on = true
    min_tls_version = "1.2"
    use_32_bit_worker_process = false
    ftps_state        = "FtpsOnly"
    http2_enabled     = true
    linux_fx_version  = "DOCKER|${var.image_repository}:${var.image_tag}"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  count          = var.vnet_integration_enabled ? 1 : 0
  app_service_id = azurerm_function_app.function_app.id
  subnet_id      = data.azurerm_subnet.subnet[count.index].id
  

}