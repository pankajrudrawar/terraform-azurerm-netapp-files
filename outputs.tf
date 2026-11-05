output "account_id" {
  description = "Resource ID of the NetApp account"
  value       = try(azurerm_netapp_account.this[0].id, null)
}

output "account_name" {
  description = "Name of the NetApp account"
  value       = try(azurerm_netapp_account.this[0].name, null)
}

output "pool_ids" {
  description = "Map of capacity pool resource IDs keyed by pool name"
  value       = { for k, v in azurerm_netapp_pool.this : k => v.id }
}

output "snapshot_policy_ids" {
  description = "Map of snapshot policy resource IDs keyed by policy name"
  value       = { for k, v in azurerm_netapp_snapshot_policy.this : k => v.id }
}

output "volume_ids" {
  description = "Map of volume resource IDs keyed by volume name"
  value       = { for k, v in azurerm_netapp_volume.this : k => v.id }
}

output "volume_mount_ip_addresses" {
  description = "Map of volume mount IP address lists keyed by volume name"
  value       = { for k, v in azurerm_netapp_volume.this : k => v.mount_ip_addresses }
}
