locals {
  app_tags = merge(
    {
      "hidden-link:${var.resource_group_id}/providers/Microsoft.Web/sites/${azurerm_function_app.function_app.name}" = "Resource"
    },
    var.tags
  )
}

module "application_insights" {
  source = "git::git@ssh.dev.azure.com:v3/AZBlue/OneAZBlue/terraform.devops.application-insights?ref=v1.0.0"

  location       = var.location
  resource_group = var.resource_group_name

  application_type = "web"

  info = var.info
  tags = local.app_tags
  
  continuous_export = {
    resource_group_name  = var.continuous_export.resource_group_name
    storage_account_name = var.continuous_export.storage_account_name
    container_name       = var.continuous_export.container_name
  }

}