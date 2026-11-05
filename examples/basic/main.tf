terraform {
  required_version = ">= 1.5.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure subscription ID. Falls back to the ARM_SUBSCRIPTION_ID environment variable when null"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

resource "azurerm_resource_group" "example" {
  name     = "rg-anf-example"
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-anf-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.20.0.0/16"]
}

# Azure NetApp Files volumes need a dedicated subnet delegated to the service
resource "azurerm_subnet" "anf" {
  name                 = "snet-anf"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.20.1.0/24"]

  delegation {
    name = "netapp"

    service_delegation {
      name    = "Microsoft.NetApp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

module "netapp_files" {
  source = "../.."

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

output "volume_mount_ip_addresses" {
  value = module.netapp_files.volume_mount_ip_addresses
}
