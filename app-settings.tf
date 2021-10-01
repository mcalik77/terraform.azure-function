locals {
  key_vault_uri = module.key_vault.key_vault_uri

  secrets_ref = [
    for secret in module.key_vault.secrets:
    {
      replace(split("/", secret.id)[4], "-", "_") = "@Microsoft.KeyVault(SecretUri=${secret.id})"
    }
  ]
  
  default_app_settings = merge(
    {
      https_only                          =  true
      FUNCTION_APP_EDIT_MODE              = "readOnly"
      DOCKER_REGISTRY_SERVER_URL          = "${data.azurerm_container_registry.registry.login_server}"
      DOCKER_REGISTRY_SERVER_USERNAME     = "${data.azurerm_container_registry.registry.admin_username}"
      APPINSIGHTS_INSTRUMENTATIONKEY      = "${module.application_insights.instrumentation_key}"
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    },
    var.app_settings
  )

 app_settings = merge(local.default_app_settings, local.secrets_ref...)

  app_settings_string = join("\" \"", [
    for key, value in local.app_settings : "${key}=${value}"
  ])
 }


resource null_resource azure_login {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      az login --service-principal \
        --username $ARM_CLIENT_ID \
        --password $ARM_CLIENT_SECRET \
        --tenant $ARM_TENANT_ID
      az account set --subscription $ARM_SUBSCRIPTION_ID
    EOF
  }

  triggers = {
    always = uuid()
  }
}

resource null_resource set_app_settings {
  provisioner local-exec {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
      az functionapp config appsettings set \
        --name "${azurerm_function_app.function_app.name}" \
        --resource-group "${var.resource_group_name}" \
        --settings "${local.app_settings_string}"
    EOF
  }

  triggers = {
    always = uuid()
    order  = null_resource.azure_login.id
  }

  depends_on = [
    module.key_vault
  ]
}