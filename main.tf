################################################################################
# NetApp account
################################################################################

resource "azurerm_netapp_account" "this" {
  count = var.create ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "active_directory" {
    for_each = var.active_directory != null ? [var.active_directory] : []

    content {
      username            = active_directory.value.username
      password            = var.active_directory_password
      domain              = active_directory.value.domain
      smb_server_name     = active_directory.value.smb_server_name
      dns_servers         = active_directory.value.dns_servers
      organizational_unit = active_directory.value.organizational_unit
    }
  }

  tags = var.tags
}

################################################################################
# Capacity pools
################################################################################

resource "azurerm_netapp_pool" "this" {
  for_each = var.create ? var.pools : {}

  name                = each.key
  account_name        = azurerm_netapp_account.this[0].name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_level       = each.value.service_level
  size_in_tb          = each.value.size_in_tb
  qos_type            = each.value.qos_type

  tags = merge(var.tags, each.value.tags)
}

################################################################################
# Snapshot policies
################################################################################

resource "azurerm_netapp_snapshot_policy" "this" {
  for_each = var.create ? var.snapshot_policies : {}

  name                = each.key
  account_name        = azurerm_netapp_account.this[0].name
  resource_group_name = var.resource_group_name
  location            = var.location
  enabled             = each.value.enabled

  dynamic "hourly_schedule" {
    for_each = each.value.hourly != null ? [each.value.hourly] : []

    content {
      snapshots_to_keep = hourly_schedule.value.snapshots_to_keep
      minute            = hourly_schedule.value.minute
    }
  }

  dynamic "daily_schedule" {
    for_each = each.value.daily != null ? [each.value.daily] : []

    content {
      snapshots_to_keep = daily_schedule.value.snapshots_to_keep
      hour              = daily_schedule.value.hour
      minute            = daily_schedule.value.minute
    }
  }

  dynamic "weekly_schedule" {
    for_each = each.value.weekly != null ? [each.value.weekly] : []

    content {
      snapshots_to_keep = weekly_schedule.value.snapshots_to_keep
      days_of_week      = weekly_schedule.value.days_of_week
      hour              = weekly_schedule.value.hour
      minute            = weekly_schedule.value.minute
    }
  }

  tags = merge(var.tags, each.value.tags)
}

################################################################################
# Volumes
################################################################################

resource "azurerm_netapp_volume" "this" {
  for_each = var.create ? var.volumes : {}

  name                = each.key
  account_name        = azurerm_netapp_account.this[0].name
  pool_name           = azurerm_netapp_pool.this[each.value.pool_key].name
  resource_group_name = var.resource_group_name
  location            = var.location

  volume_path                = each.value.volume_path
  service_level              = coalesce(each.value.service_level, var.pools[each.value.pool_key].service_level)
  subnet_id                  = each.value.subnet_id
  protocols                  = each.value.protocols
  storage_quota_in_gb        = each.value.storage_quota_in_gb
  network_features           = each.value.network_features
  security_style             = each.value.security_style
  snapshot_directory_visible = each.value.snapshot_directory_visible
  throughput_in_mibps        = each.value.throughput_in_mibps
  zone                       = each.value.zone

  dynamic "export_policy_rule" {
    for_each = each.value.export_policy_rules

    content {
      rule_index          = export_policy_rule.value.rule_index
      allowed_clients     = export_policy_rule.value.allowed_clients
      protocols_enabled   = export_policy_rule.value.protocols_enabled
      unix_read_only      = export_policy_rule.value.unix_read_only
      unix_read_write     = export_policy_rule.value.unix_read_write
      root_access_enabled = export_policy_rule.value.root_access_enabled
    }
  }

  dynamic "data_protection_snapshot_policy" {
    for_each = each.value.snapshot_policy_key != null ? [each.value.snapshot_policy_key] : []

    content {
      snapshot_policy_id = azurerm_netapp_snapshot_policy.this[data_protection_snapshot_policy.value].id
    }
  }

  tags = merge(var.tags, each.value.tags)
}
