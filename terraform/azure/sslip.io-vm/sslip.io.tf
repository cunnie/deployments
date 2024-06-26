# Create VM for sslip.io DNS server on Azure
#
# terraform apply -auto-approve -var="admin_password=Aa1_$(dd if=/dev/random bs=1 count=6 | base64)"
# terraform apply -destroy -auto-approve -var=admin_password=Admin\!23
#
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

variable "managed_disk_id" {
  type        = string
  description = "id of the managed disk (persistent disk for etcd data)"
}

variable "admin_password" {
  type        = string
  description = "password of the admin user for provisioning"
}

variable "azurerm_storage_account_primary_blob_endpoint" {
  type        = string
  description = "Storage Account Blob Endpoint"
}

data "cloudinit_config" "sslip_io" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "cloud-init"
    content_type = "text/x-shellscript"
    content      = file("install_ns-azure.sh")
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "sslip_io" {
  name                            = "ns-azure.sslip.io"
  location                        = "southeastasia"
  resource_group_name             = var.resource_group_name
  network_interface_ids           = [var.network_interface_id]
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  custom_data                     = data.cloudinit_config.sslip_io.rendered

  os_disk {
    name                 = "sslip.io"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # az vm image list --publisher Canonical -o table --all
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = var.azurerm_storage_account_primary_blob_endpoint
  }
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.sslip_io.public_ip_address
}

output "admin_password" {
  value = var.admin_password
}
