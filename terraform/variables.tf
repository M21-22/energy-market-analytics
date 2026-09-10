variable "project_name" {
  description = "Short project name used in Azure resource names."
  type        = string
  default     = "energyanalytics"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for project resources."
  type        = string
  default     = "West Europe"
}

variable "sql_admin_login" {
  description = "Administrator login for the Synapse SQL endpoint."
  type        = string
  default     = "synapseadmin"
}

variable "sql_admin_password" {
  description = "Administrator password for the Synapse SQL endpoint. Load through TF_VAR_sql_admin_password."
  type        = string
  sensitive   = true
}

variable "synapse_sql_pool_sku" {
  description = "Dedicated SQL Pool performance level."
  type        = string
  default     = "DW100c"
}

variable "synapse_backup_storage_type" {
  description = "Backup storage redundancy for the Dedicated SQL Pool."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS"], var.synapse_backup_storage_type)
    error_message = "synapse_backup_storage_type must be LRS or GRS."
  }
}

variable "allowed_ip_address" {
  description = "Optional public IPv4 address allowed through the Synapse firewall. Load through TF_VAR_allowed_ip_address."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Common Azure resource tags."
  type        = map(string)

  default = {
    project     = "energy-market-analytics"
    environment = "dev"
    managed_by  = "terraform"
  }
}
