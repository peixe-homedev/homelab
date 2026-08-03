# --- VIRTUAL MACHINE DEFINITION ---
resource "proxmox_virtual_environment_vm" "app-server" {
  name      = "app-server"
  node_name = "pve" # The name of your physical laptop node in Proxmox
  vm_id     = 203   # Matching the ID to the last octet of your IP (10.0.1.203)

  # Hardware Globals
  scsi_hardware = "virtio-scsi-pci" # Matches the template script

  # Tells Proxmox to use the Liinux template as the starting point
  clone {
    vm_id = 9001
  }

  cpu {
    cores = 2 
    type ="host"
  }

  memory {
    dedicated = 2048
  }

  # Required for Proxmox to show the VM's internal IP and status correctly
  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0" # The default Proxmox virtual bridge
  }

  # --- STORAGE ---
  # DISK 1: Operating System
  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0" # Primary boot disk
    size         = 15      # In GB
  }

  # DISK 2: Dedicated storage for data
  # This makes it easier to expand or backup data separately later
  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi1"
    size         = 20      # In GB
    serial       = "APPDATA01"
  }

  # --- CLOUD-INIT (THE "AUTOPILOT") ---
  initialization {
    datastore_id = "local-lvm" # Proxmox needs a place to store the temp cloud-init config
    
    ip_config {
      ipv4 {
        address = "10.0.1.203/24" # Static IP assignment
        gateway = "10.0.1.1"
      }
    }

    # DNS BLOCK:
    dns {
      servers = ["10.0.1.2", "8.8.8.8"]
    }
    
    # Injects your SSH Public Key so you can log in without a password later
    user_account {
      username = "ubuntu"  
      keys = [var.ssh_public_key]
    }

  }
  lifecycle {
    ignore_changes = [
      clone,
      initialization,
    ]
  }
}
