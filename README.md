# Azure Function 
Terraform module that provisions an azure Function. When you choose sku to "Premium", you have option to create private endpoints,  georeplication_locations and network_rule_set ( White list the ip_rule). You can also choose to create a service enpoints but Microsoft recomended using private endpoints instead of service endpoints in most network scenarios bc there are some limitation using service enpoint. [More info to check](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-vnet)
You can integrate private endpoint with azure function itself, storage account, keyvault and application insight. It is integrated with storage module and keyvault module. 

## Usage
You can include the module by using the following code:

```
# Azure Function

## Resource Group Module
module "rg" {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.resource-group?ref=v0.0.5"

  info = var.info
  tags = var.tags

  location = var.location
}

# Azure Function Module
module "azure_function" {

  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.azure-function?ref=v2.0.0"
  
  info = var.info
  tags = local.tags
  
  resource_group_name = module.resource_group.name
  resource_group_id   = module.resource_group.id
  location            = module.resource_group.location

  app_service_plan_resource_group_name = module.resource_group.name
  app_service_plan_name                = module.app_service_plan.name

  ip_whitelist            = var.ip_whitelist
  os_type                 = var.os_type
  registry_name           = var.registry_name
  registry_resource_group = var.registry_resource_group
  image_repository        = var.image_repository
  image_tag               = var.image_tag
  app_service_environment_name = ""
  vnet_integration_enabled = false 
  subnet                   = var.virtual_network

  private_endpoint_subnet            = var.private_endpoint_subnet 
  subresource_names_storage          = var.subresource_names_storage
  private_endpoint_resources_enabled = var.private_endpoint_resources_enabled

  continuous_export = var.continuous_export

  managed_identities = []

  app_settings = merge(var.app_settings, {
    WEBSITE_RUN_FROM_PACKAGE                = 0
    FileIngressServiceBus__TopicName        = "file-ingress"
    FileIngressServiceBus__SubscriptionName = "redcard-return"
    FileIngressBlobStorage__ContainerName   = "redcard-return"
    TempBlobStorage__ContainerName          = "file-cache"
    OnBase__RetryCount                      = 3
    OnBase__RetryWaitInSeconds              = 300
  })

  secrets = [
    {
      key   = "FileIngressServiceBus--ConnectionString"
      value = data.azurerm_servicebus_namespace.fis_service_bus.default_primary_connection_string
    },
    {
      key   = "FileIngressBlobStorage--ConnectionString"
      value = data.azurerm_storage_account.fis_storage_account.primary_blob_connection_string
    },
    {
      key   = "TempBlobStorage--ConnectionString",
      value = module.storage_account.connection_string
    }
  ]
}
```

## Inputs

The following are the supported inputs for the module.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| info | Info object used to construct naming convention for all resources. | `object` | n/a | yes |
| tags | Tags object used to tag resources. | `object` | n/a | yes |
| resource_group | Name of the resource group where Azure Event Grid Subscription will be deployed. | `string` | n/a | yes |
| location | Location of Azure Event Grid Subscription. | `string` | n/a | yes |
| resource_group_id | The ID of the Resource Group | `string` | n/a | yes |
| app_service_plan_resource_group_name | Name of the resource group for app service plan | `string` | n/a | yes |
| app_service_plan_name | Name of the app service plan for function | `string` | n/a | yes |
| os_type | A string indicating the Operating System type for this function app | `string` | n/a | no |
| ip_whitelist | White list of ip rules | `string` | N/A | no |
| registry_name | Name of registry for docker image of fucntion | `string` | N/A | yes |
| registry_resource_group | Name of resource group of registry for docker image of fucntion | `string` | N/A | yes |
| image_repository | Name of repository for docker image of fucntion | `string` | N/A | yes |
| image_tag | Tag  of docker image of fucntion | `string` | N/A | yes |
| managed_identities | The name of manage identities(Service principal or Application, Function name) to give key-vault access | `list(object)` | [] | no |
| app_service_environment_name | Name of app service environment | `string` | "" | yes |
| vnet_integration_enabled | it is enabling to vnet integration for keyvault | `bool` | false | no |
| private_endpoint_subnet |Object that contains information to lookup the subnet to use for the privat endpoint. When private_endpoint_enabled is set to true this variable is required, otherwise it is optional  | `list of object` | [] | no |
|subresource_names_storage | List of the subresource names for storage account to enable private endpoints | `list` | N/A | no |
| private_endpoint_resources_enabled | Determines if private endpoint should be enabled for specific resources, [] to disable private endpoint.  | `list` | `["sites", "keyVault", "blob", "table"]` | no |
| dns_resource_group_name | DNS resource group name | `string` | `hubvnetrg`| no |