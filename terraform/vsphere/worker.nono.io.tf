terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

provider "vsphere" {
  user           = "a@vsphere.local"
  password       = var.vsphere_password
  vsphere_server = "vcenter-80.nono.io"
}

data "vsphere_datacenter" "dc" {
  name = "dc"
}

data "vsphere_compute_cluster" "cl" {
  name          = "cl"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "cunnie"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "guest"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = "NAS-0"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "worker.nono.io"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 4
  memory   = 32768

  guest_id                = "fedora64Guest" # "ubuntu64Guest"
  firmware                = "efi"
  boot_delay              = 5000
  enable_disk_uuid        = true
  efi_secure_boot_enabled = false

  network_interface {
    network_id     = data.vsphere_network.network.id
    use_static_mac = true
    mac_address    = "02:00:00:00:02:F8"
  }

  disk {
    label            = "root"
    size             = 250
    thin_provisioned = true
  }

  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path         = "ISO/Fedora-Server-dvd-x86_64-41-1.4.iso"
  }

  extra_config = {
    "bios.bootOrder" = "disk,cdrom"
  }
}

variable "vsphere_password" {
  description = "vSphere password"
}
