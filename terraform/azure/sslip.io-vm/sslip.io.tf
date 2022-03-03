# Create VM for sslip.io DNS server on Azure

# From https://docs.microsoft.com/en-us/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure#2-implement-the-terraform-code

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

variable "resource_group_name" {
  type        = string
  description = "name of the Resource Group"
}

variable "network_interface_id" {
  type        = string
  description = "id of the network interface"
}

variable "admin_password" {
type = string
description = "password of the admin user for provisioning"
}

variable "azurerm_storage_account_primary_blob_endpoint" {
  type        = string
  description = "Storage Account Blob Endpoint"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "sslip_io" {
  name                  = "ns-azure.sslip.io"
  location              = "southeastasia"
  resource_group_name   = var.resource_group_name
  network_interface_ids = [var.network_interface_id]
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = var.admin_password
  disable_password_authentication = false

  os_disk {
    name                 = "sslip.io"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-impish"
    sku       = "21_10"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "ls -la /tmp/",
    ]

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }

  boot_diagnostics {
    storage_account_uri = var.azurerm_storage_account_primary_blob_endpoint
  }
}
