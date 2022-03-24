# Create Infrastructure for sslip.io DNS server on Azure

# From https://docs.microsoft.com/en-us/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure#2-implement-the-terraform-code

# Thanks for IPv6 info:
# https://serverfault.com/a/1014499/334329

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "azure_ipv4_id" {
  type        = string
  description = "ns-azure.sslip.io IPv4"
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "sslip_io" {
  name     = "sslip.io"
  location = "southeastasia"
}

# Create virtual network
resource "azurerm_virtual_network" "sslip_io" {
  name                = "sslip.io"
  address_space       = ["10.11.0.0/16", "fc00:11::/48"]
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.sslip_io.name
}

# Create subnet
resource "azurerm_subnet" "sslip_io" {
  name                 = "ipv4.sslip.io"
  resource_group_name  = azurerm_resource_group.sslip_io.name
  virtual_network_name = azurerm_virtual_network.sslip_io.name
  address_prefixes     = ["10.11.0.0/24", "fc00:11::/64"]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "sslip_io" {
  name                = "sslip.io"
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.sslip_io.name

  security_rule {
    name                       = "allow everything"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "sslip_io" {
  name                = "sslip.io"
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.sslip_io.name

  ip_configuration {
    name                          = "ipv4.sslip.io"
    subnet_id                     = azurerm_subnet.sslip_io.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = var.azure_ipv4_id
  }
  ip_configuration {
    name                          = "ipv6.sslip.io"
    subnet_id                     = azurerm_subnet.sslip_io.id
    private_ip_address_version    = "IPv6"
    private_ip_address_allocation = "Dynamic"
    primary                       = false
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "sslip_io" {
  network_interface_id      = azurerm_network_interface.sslip_io.id
  network_security_group_id = azurerm_network_security_group.sslip_io.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "sslip_io" {
  name                     = "sslipio"
  resource_group_name      = azurerm_resource_group.sslip_io.name
  location                 = "southeastasia"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
