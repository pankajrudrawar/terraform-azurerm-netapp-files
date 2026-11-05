# terraform-azurerm-netapp-files

Terraform module for Azure NetApp Files: NetApp account, capacity pools, snapshot policies and NFS or SMB volumes with export policies.

[![Validate](https://github.com/pankajrudrawar/terraform-azurerm-netapp-files/actions/workflows/validate.yml/badge.svg)](https://github.com/pankajrudrawar/terraform-azurerm-netapp-files/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
![Terraform](https://img.shields.io/badge/terraform-%E2%89%A5%201.5.7-7B42BC?logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-module-0078D4)

## Features

- Capacity pools with Standard, Premium or Ultra service level and Auto or Manual QoS
- Volumes defined as a map and bound to pools by key; service level inherited from the pool
- NFSv3, NFSv4.1 and SMB volumes with export policy rules
- Hourly, daily and weekly snapshot policies attached by key
- Optional Active Directory connection for SMB

## Usage

```hcl
module "netapp_files" {
  source = "github.com/pankajrudrawar/terraform-azurerm-netapp-files"

  name                = "anf-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  pools = {
    premium = {
      service_level = "Premium"
      size_in_tb    = 2
    }
  }

  snapshot_policies = {
    daily-7 = {
      daily = {
        snapshots_to_keep = 7
        hour              = 2
      }
    }
  }

  volumes = {
    data01 = {
      pool_key            = "premium"
      volume_path         = "data01"
      subnet_id           = azurerm_subnet.anf.id
      storage_quota_in_gb = 1024
      protocols           = ["NFSv4.1"]
      snapshot_policy_key = "daily-7"

      export_policy_rules = [
        {
          rule_index      = 1
          allowed_clients = ["10.20.0.0/16"]
        }
      ]
    }
  }

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
```

A complete, runnable configuration is in [`examples/basic`](examples/basic).

## Notes

- Volumes require a subnet delegated to `Microsoft.NetApp/volumes`. The example creates one, and the virtual network module in this collection can too.
- Azure NetApp Files must be registered and quota-approved in your subscription before the first deployment.
- The Active Directory password is a separate `sensitive` variable and is stored in Terraform state.

## Module reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| azurerm | >= 4.0, < 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create | Controls whether any resources are created by this module | `bool` | `true` | no |
| name | Name of the NetApp account | `string` | n/a | yes |
| resource_group_name | Name of the resource group that holds the NetApp account | `string` | n/a | yes |
| location | Azure region, for example `eastus2` | `string` | n/a | yes |
| active_directory | Active Directory connection, required for SMB volumes. The service account password goes in `active_directory_password` | `object` | `null` | no |
| active_directory_password (sensitive) | Password of the Active Directory service account | `string` | `null` | no |
| pools | Map of capacity pools keyed by pool name. `size_in_tb` is 1 to 2048 | `map(object)` | `{}` | no |
| snapshot_policies | Map of snapshot policies keyed by policy name | `map(object)` | `{}` | no |
| volumes | Map of volumes keyed by volume name. `pool_key` must match a key in `pools` and `subnet_id` must be delegated to Microsoft.NetApp/volumes | `map(object)` | `{}` | no |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| account_id | Resource ID of the NetApp account |
| account_name | Name of the NetApp account |
| pool_ids | Map of capacity pool resource IDs keyed by pool name |
| snapshot_policy_ids | Map of snapshot policy resource IDs keyed by policy name |
| volume_ids | Map of volume resource IDs keyed by volume name |
| volume_mount_ip_addresses | Map of volume mount IP address lists keyed by volume name |
<!-- END_TF_DOCS -->

## Contributing

Run `pre-commit run -a` before opening a pull request. It formats the code, validates it, runs TFLint and refreshes the reference tables above with terraform-docs.

## License

Apache 2.0. See [LICENSE](LICENSE).
