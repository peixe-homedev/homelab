# --- PROVIDER CONFIGURATION ---
# This block tells Terraform which "plugin" to download to talk to Proxmox.
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox" 
      version = "0.66.1"
    }
  }
}

# This block uses the variables from the .tfvars file to authenticate.
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  # Combines Token ID and Secret into the format Proxmox expects: ID=SECRET
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true # Allows connection even if your Proxmox SSL certificate is self-signed

  ssh{
    agent = false
    username = "root"
    password = var.pve_password
  }
}