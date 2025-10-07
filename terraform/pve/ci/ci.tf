terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.80"
    }
  }
}

provider "proxmox" {
  endpoint = "https://pve.nono.io:8006/"
  # must be root because "only root can set 'hookscript' config"
  username = "root@pam"
  # must be password, not API token,  because "proxmox_virtual_environment_file"
  password = var.password
  insecure = true
}

variable "password" {
  description = "Proxmox user password"
  type        = string
  sensitive   = true
}

resource "proxmox_virtual_environment_vm" "concourse" {
  name      = "concourse"
  vm_id     = 2224
  node_name = "pve"
  # Do NOT use "hook_script_file_id"; it runs the hook on the HOST not the VM
  # hook_script_file_id = proxmox_virtual_environment_file.post_install_script.id

  # we want all our VMs to run the qemu-guest-agent
  agent {
    enabled = true
  }

  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
  }
  memory {
    dedicated = 65536 # 64 GiB in MB
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 384 # Size in GiB
  }

  # Clone from template
  clone {
    vm_id = 1000
  }

  # Cloud-init configuration inline
  initialization {
    ip_config {
      ipv4 {
        address = "10.9.2.224/24"
        gateway = "10.9.2.1"
      }
      ipv6 {
        address = "2601:646:100:69f1::e0/64"
        gateway = "2601:646:100:69f1::"
      }

    }
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "02:00:00:00:02:e0"
    vlan_id     = 2
  }

  operating_system {
    type = "l26" # Linux 2.6 kernel and later
  }
  boot_order = ["scsi0"]
}

# We can't use API token; we must user/pass because this resource.
# "The resource with this content type uses SSH access to the node. You might need to configure the ssh option in the provider section"
# https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file
# Cloud-init configuration file
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_file {
    path = "cloud-init-ci.yaml"
  }
}

output "vm_info" {
  value = {
    name   = proxmox_virtual_environment_vm.concourse.name
    vmid   = proxmox_virtual_environment_vm.concourse.vm_id
    node   = proxmox_virtual_environment_vm.concourse.node_name
    cores  = proxmox_virtual_environment_vm.concourse.cpu[0].cores
    memory = proxmox_virtual_environment_vm.concourse.memory[0].dedicated
  }
}
