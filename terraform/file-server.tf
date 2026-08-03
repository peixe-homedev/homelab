resource "proxmox_virtual_environment_vm" "nextcloud_vm" {
  name      = "file-server"
  node_name = "pve"
  vm_id     = 204 # Incremented from your previous 204

  clone {
    vm_id = 9002 # Assuming this is your trusted Debian 12 virt-customize template
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048 # Increased to 2GB to comfortably handle PHP, Nginx, and Redis
    floating  = 1024 # Allows Proxmox to reclaim up to 1GB if the VM is idling
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 30 # Bumped to 30GB for the OS, Docker images, and local DB logs
    ssd          = true
    discard      = "on"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "10.0.1.204/24" # Adjusted to match the new VM ID
        gateway = "10.0.1.1"
      }
    }

    dns {
      servers = ["10.0.1.2", "8.8.8.8"]
    }

    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }

  lifecycle {
    ignore_changes = [
      clone,
      initialization,
    ]
  }
}