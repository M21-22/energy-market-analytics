resource "azurerm_monitor_action_group" "pipeline_alerts" {
  name                = "ag-${var.project_name}-${var.environment}-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "pipeline"

  email_receiver {
    name          = "pipeline-alert"
    email_address = var.alert_email
  }

  tags = var.tags
}


resource "azurerm_monitor_metric_alert" "adf_pipeline_failure" {
  name                = "alert-adf-pipeline-failure-${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_data_factory.main.id]

  description = "Alert when the main energy market pipeline fails."
  severity    = 2

  frequency   = "PT5M"
  window_size = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DataFactory/factories"
    metric_name      = "PipelineFailedRuns"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 1

    dimension {
      name     = "Name"
      operator = "Include"

      values = [
        "pl_energy_market_incremental"
      ]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.pipeline_alerts.id
  }

  tags = var.tags
}