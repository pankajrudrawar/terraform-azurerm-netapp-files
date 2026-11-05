variable "create" {
  description = "Controls whether any resources are created by this module"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the NetApp account"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group that holds the NetApp account"
  type        = string
}

variable "location" {
  description = "Azure region, for example `eastus2`"
  type        = string
}

variable "active_directory" {
  description = "Active Directory connection, required for SMB volumes. The service account password goes in `active_directory_password`"
  type = object({
    username            = string
    domain              = string
    smb_server_name     = string
    dns_servers         = list(string)
    organizational_unit = optional(string)
  })
  default = null
}

variable "active_directory_password" {
  description = "Password of the Active Directory service account"
  type        = string
  default     = null
  sensitive   = true
}

variable "pools" {
  description = "Map of capacity pools keyed by pool name. `size_in_tb` is 1 to 2048"
  type = map(object({
    service_level = string
    size_in_tb    = number
    qos_type      = optional(string, "Auto")
    tags          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.pools) : contains(["Standard", "Premium", "Ultra"], p.service_level)])
    error_message = "Each pool service_level must be Standard, Premium or Ultra."
  }
}

variable "snapshot_policies" {
  description = "Map of snapshot policies keyed by policy name"
  type = map(object({
    enabled = optional(bool, true)
    hourly = optional(object({
      snapshots_to_keep = number
      minute            = optional(number, 0)
    }))
    daily = optional(object({
      snapshots_to_keep = number
      hour              = optional(number, 0)
      minute            = optional(number, 0)
    }))
    weekly = optional(object({
      snapshots_to_keep = number
      days_of_week      = list(string)
      hour              = optional(number, 0)
      minute            = optional(number, 0)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "volumes" {
  description = "Map of volumes keyed by volume name. `pool_key` must match a key in `pools` and `subnet_id` must be delegated to Microsoft.Netapp/volumes"
  type = map(object({
    pool_key                   = string
    volume_path                = string
    subnet_id                  = string
    storage_quota_in_gb        = number
    protocols                  = optional(list(string), ["NFSv4.1"])
    service_level              = optional(string)
    network_features           = optional(string, "Standard")
    security_style             = optional(string)
    snapshot_directory_visible = optional(bool, true)
    throughput_in_mibps        = optional(number)
    zone                       = optional(string)
    snapshot_policy_key        = optional(string)
    export_policy_rules = optional(list(object({
      rule_index          = number
      allowed_clients     = list(string)
      protocols_enabled   = optional(list(string), ["NFSv4.1"])
      unix_read_only      = optional(bool, false)
      unix_read_write     = optional(bool, true)
      root_access_enabled = optional(bool, false)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
