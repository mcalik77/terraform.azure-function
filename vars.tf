terraform {
  experiments = [module_variable_optional_attrs]
}

variable info {
  type = object({
    domain      = string
    subdomain   = string
    environment = string
    sequence    = string
  })

  description = "Info object used to construct naming convention for all resources."
}
variable tags {
  type = object({
    environment = string
    source      = string
  })

  description = "Tags object used to tag resources."
}

variable ip_whitelist {
  description = "List of public IP or IP ranges in CIDR Format to allow."
  default     = ["204.153.155.151/32"]
}

variable app_service_plan_name {}

variable app_service_plan_resource_group_name {}

variable location {}

variable resource_group_name {}

variable resource_group_id {}

variable app_service_environment_name {
  type    = string 
  default = ""
}

variable function_app_name {}

variable secrets{
  type = list(object(
    {
      key   = string
      value = string
    }
  ))
  default = []
}

variable subnet{
  type = object (
    {
      virtual_network_name                = string
      virtual_network_subnet_name         = string
      virtual_network_resource_group_name = string
    }
  )

  default = {
    virtual_network_name                = null
    virtual_network_subnet_name         = null
    virtual_network_resource_group_name = null
  }
}


variable app_settings {
  default = {}
}


variable registry_name {}

variable registry_resource_group {}

variable os_type {}

variable function_version {
  type    = string
  default = "~3"
}

variable https_only {
  type = bool
  default = true
}


variable enable_builtin_logging {
  type = bool
  default = false
}


variable vnet_integration_enabled {
  type        = bool
  description = "Determines if vnet integration should be enabled for the function."
  default = false
}
variable image_repository {}

variable image_tag {}
    
variable continuous_export {
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
  })
}

variable private_endpoint_subnet{
  type = object (
    {
      virtual_network_name                = string
      virtual_network_subnet_name         = string
      virtual_network_resource_group_name = string
    }
  )

  default = {
    virtual_network_name                = null
    virtual_network_subnet_name         = null
    virtual_network_resource_group_name = null
  }
}

variable subresource_names_storage {
     type = list
     default = []
     
}

variable private_endpoint_resources_enabled {
  type  = list
  default = ["sites", "keyVault", "blob", "table"]
  
  validation {
    condition = length([
      for resource in var.private_endpoint_resources_enabled : true
      if contains(["keyVault"], resource  ) || 
         contains(["sites"], resource     ) ||
         contains(["blob"], resource      ) ||
         contains(["table"], resource     ) ||
         contains(["queue"], resource     ) ||
         contains([ "web"], resource      )]) == length(var.private_endpoint_resources_enabled)

    error_message = "The private_endpoint_resources_enabled list must be one of [\"keyVault\", \"sites\", \"blob\", \"table\", \"queue\", \"web\"]."
    
  }
}

variable managed_identities {
  type = list(object({
    principal_name = string
    roles          = optional(list(string))
  }))
  description = "The name of manage identities(Service principal or Application name) to give key-vault access"
  default = []
}