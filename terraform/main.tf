resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  compact_name = substr(
    lower(replace("${var.project_name}${var.environment}", "-", "")),
    0,
    14
  )

  suffix = random_string.suffix.result
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# ADLS Gen2
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "datalake" {
  name                     = "st${local.compact_name}${local.suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "curated" {
  name               = "curated"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.datalake.id
}

# -----------------------------------------------------------------------------
# Azure Data Factory
# -----------------------------------------------------------------------------

resource "azurerm_data_factory" "main" {
  name                = "adf-${var.project_name}-${var.environment}-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "adf_storage" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.main.identity[0].principal_id
}

# -----------------------------------------------------------------------------
# Azure Functions - Flex Consumption
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "functions" {
  name                     = "stfn${local.compact_name}${local.suffix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_container" "function_deployment" {
  name                  = "function-deployment"
  storage_account_id    = azurerm_storage_account.functions.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "functions" {
  name                = "asp-${var.project_name}-${var.environment}-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "FC1"

  tags = var.tags
}

resource "azurerm_function_app_flex_consumption" "main" {
  name                = "func-${local.compact_name}-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.functions.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.functions.primary_blob_endpoint}${azurerm_storage_container.function_deployment.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.functions.primary_access_key

  runtime_name    = "python"
  runtime_version = "3.12"

  maximum_instance_count = 2
  instance_memory_in_mb  = 2048

  identity {
    type = "SystemAssigned"
  }

  site_config {}

  tags = var.tags
}

resource "azurerm_role_assignment" "function_storage" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.main.identity[0].principal_id
}

# -----------------------------------------------------------------------------
# Azure Synapse Analytics
# -----------------------------------------------------------------------------

resource "azurerm_synapse_workspace" "main" {
  name                                 = "syn-${var.project_name}-${var.environment}-${local.suffix}"
  resource_group_name                  = azurerm_resource_group.main.name
  location                             = azurerm_resource_group.main.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id

  sql_administrator_login          = var.sql_admin_login
  sql_administrator_login_password = var.sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "synapse_storage" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.main.identity[0].principal_id
}

resource "azurerm_synapse_firewall_rule" "client" {
  count = var.allowed_ip_address == null ? 0 : 1

  name                 = "AllowClient"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = var.allowed_ip_address
  end_ip_address       = var.allowed_ip_address
}

resource "azurerm_synapse_sql_pool" "warehouse" {
  name                 = "energydw"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  sku_name             = var.synapse_sql_pool_sku
  create_mode          = "Default"

  # Required by AzureRM 5.x. LRS is the lower-cost backup-storage option.
  storage_account_type      = var.synapse_backup_storage_type
  geo_backup_policy_enabled = false

  tags = var.tags
}
