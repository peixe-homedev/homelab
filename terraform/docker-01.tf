resource "proxmox_virtual_environment_container" "docker_lxc" {
  node_name = "pve"
  vm_id     = 202

  # Container OS and Version
  operating_system {
    # Make sure this template exists in your storage 'local'
    # You might need to run 'pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst'
    template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst" 
    type             = "ubuntu"
  }

  cpu {
    cores = 2  # Docker builds can be CPU hungry; 2 is safer than 1
  }

  memory {
    dedicated = 2048 # Increased to 2GB for Docker daemon + Containers
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 16  # Increased to 16GB. Docker images eat disk space quickly.
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "docker-01" 
    
    ip_config {
      ipv4 {
        address = "10.0.1.202/24" # New Static IP
        gateway = "10.0.1.1"
      }
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }

  # --- CRITICAL FOR DOCKER ---
  # These features allow Docker to run inside the LXC
  features {
    nesting = true
    # keyctl  = true 
  }

  unprivileged = true # Safe to keep unprivileged if nesting is on
  started      = true
}