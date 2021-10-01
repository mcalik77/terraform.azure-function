locals { 
  secrets = concat(
    [
      {
        key              = "DOCKER-REGISTRY-SERVER-PASSWORD"
        value            = data.azurerm_container_registry.registry.admin_password
      }
    ],
     var.secrets
  )
  subnet_whitelist = var.app_service_environment_name != "" ? [
    {
      virtual_network_name                = data.external.get_ase_subnet[0].result["ase_vnet"] 
      virtual_network_subnet_name         = data.external.get_ase_subnet[0].result["ase_vnet_subnet"]
      virtual_network_resource_group_name = data.external.get_ase_subnet[0].result["ase_vnet_resource_group"]
    }
  ] : []

  subnet_whitelist_merged = (
    var.vnet_integration_enabled ? 
    concat(local.subnet_whitelist,[{
      virtual_network_name                = data.azurerm_subnet.subnet[0].virtual_network_name
      virtual_network_subnet_name         = data.azurerm_subnet.subnet[0].name
      virtual_network_resource_group_name = data.azurerm_subnet.subnet[0].resource_group_name
    }]) : local.subnet_whitelist
    )

  ip_whitelist = var.app_service_environment_name != ""? var.ip_whitelist: concat(var.ip_whitelist, [data.external.get_virtual_ip[0].result["virtual_ip"]])

  managed_identities = concat(var.managed_identities, [
     {
        principal_name = azurerm_function_app.function_app.name // function name 
     }
  ])
}

data external get_ase_subnet {
  
  count   = var.app_service_environment_name != "" ? 1 : 0
  program = ["sh", "${path.module}/get_ase_subnet.sh"]
  
  query = {
    ase_name = var.app_service_environment_name   
  }
}

data external get_virtual_ip {
  count   = var.app_service_environment_name != "" ? 0 : 1
  program = ["sh", "${path.module}/get_virtual_ip.sh"]

  query = {
    hostname = azurerm_function_app.function_app.default_hostname
  }
}

module key_vault {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.key-vault?ref=v3.0.0"

  info = var.info
  tags = var.tags

  resource_group_name = var.resource_group_name
  location            = var.location

  ip_rules_list    = local.ip_whitelist
  subnet_whitelist = local.subnet_whitelist_merged

  managed_identities = local.managed_identities

  secrets_list = local.secrets
  sku          = "standard"

  private_endpoint_subnet = var.private_endpoint_subnet

  private_endpoint_enabled = (
    contains(var.private_endpoint_resources_enabled, "vault") ? true : false
  )

  depends_on = [data.external.get_ase_subnet]
}