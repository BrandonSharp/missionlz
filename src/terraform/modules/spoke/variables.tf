# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "location" {
  description = "The region for spoke network deployment"
}

variable "hub_subid" {
  description = "Subscription ID for the hub network deployment"
}

variable "hub_rgname" {
  description = "Resource Group for the hub network deployment"
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the hub network deployment"
}

variable "laws_name" {
  description = "Log Analytics Workspace name for the deployment"
}

variable "laws_location" {
  description = "Log Analytics Workspace location"
}

variable "laws_workspace_id" {
  description = "Log Analytics Workspace workspace ID"
}

variable "laws_resource_id" {
  description = "Log Analytics Workspace Azure Resource ID"
}

variable "firewall_private_ip" {
  description = "Private IP of the Firewall"
}

variable "spoke_subid" {
  description = "Subscription ID for the spoke network deployment"
}

variable "spoke_rgname" {
  description = "Resource Group for the spoke network deployment"
}

variable "spoke_vnetname" {
  description = "Virtual Network Name for the spoke network deployment"
}

#################################
# Network configuration section
#################################
variable "spoke_vnet_address_space" {
  description = "Address space prefixes for the spoke network"
  type        = list(string)
}

variable "subnets" {
  description = "A complex object that describes subnets for the spoke network"
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  }))
}

variable "tags" {
  type = map(string)
}