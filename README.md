# homelab

Terraform and Ansible configuration for a small Proxmox home lab running real production workloads.

---

## What this does

This repo manages the infrastructure for a personal home lab that runs the vb-manager volleyball team management stack (a FastAPI backend, a Streamlit frontend, and a Nextcloud instance for file storage). A separate Keycloak VM was started and stalled — it remains in the repo in its current state.

The lab runs on a single physical machine with Proxmox VE as the hypervisor. Terraform provisions the VMs; Ansible handles everything that happens inside them.

**Note:** Real IPs, hostnames, and personal identifiers have been replaced with placeholders in this showcase copy. The actual network uses a private subnet. See `terraform/terraform.tfvars.example` and `ansible/host_vars/db-server/.vault.example` for the expected variable shapes.

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Hypervisor | Proxmox VE |
| VM provisioning | Terraform (`bpg/proxmox` provider 0.66.1) |
| Configuration management | Ansible |
| Database | PostgreSQL 17 (AlmaLinux, native install) |
| Application containers | Docker / Docker Compose |
| File storage | Nextcloud (Docker, Debian) |
| Secrets | Ansible Vault (per-host encrypted vault files) |

---

## Infrastructure layout

```
Proxmox VE (10.0.1.3)
├── db-server     (10.0.1.201, AlmaLinux)  — PostgreSQL 17 + API container
├── app-server    (10.0.1.203, Ubuntu)     — Streamlit app container
├── file-server   (10.0.1.204, Debian)     — Nextcloud + WD NAS SMB mount
├── docker-01     (10.0.1.202, root)       — Portainer
└── keycloak-01   (10.0.1.200, root)       — Keycloak [stalled]
```

---

## Getting started

**Prerequisites:** Terraform, Ansible, a Proxmox VE instance, and `ansible-vault`.

### Provision VMs with Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Fill in your Proxmox API URL, token, SSH key, and other values
terraform init
terraform plan
terraform apply
```

### Configure hosts with Ansible

Each host has a flat directory of playbooks under `ansible/<hostname>/`. Host-specific variables live in `ansible/host_vars/<hostname>/vars.yml`; sensitive values (passwords, tokens) go in an Ansible-vault-encrypted `vault` file alongside it.

```bash
# Run a specific playbook (example: deploy the API on db-server)
ansible-playbook ansible/db-server/deploy_api.yml -i ansible/inventory.ini --ask-vault-pass

# Initial host setup
ansible-playbook ansible/db-server/set_up_host.yml -i ansible/inventory.ini --ask-vault-pass
```

See each playbook directory for available playbooks.

---

## Repository structure

```
homelab/
├── terraform/
│   ├── provider.tf          # bpg/proxmox provider config (reads from tfvars)
│   ├── variables.tf         # Variable declarations
│   ├── db-server.tf         # PostgreSQL VM definition
│   ├── app-server.tf        # Streamlit VM definition
│   ├── file-server.tf       # Nextcloud VM definition
│   ├── docker-01.tf         # Docker/Portainer VM definition
│   ├── keycloak-01.tf.stalled  # Keycloak (not active)
│   └── terraform.tfvars.example
└── ansible/
    ├── inventory.ini
    ├── ansible.cfg
    ├── db-server/           # PostgreSQL setup, API deploy, RBAC, backups
    ├── app-server/          # Streamlit app deploy
    ├── file-server/         # Nextcloud deploy
    ├── docker-01/           # Portainer install
    ├── keycloak-01/         # Keycloak install [stalled]
    └── host_vars/           # Per-host vars + vault files
```

---

## Design decisions and gaps

**Flat playbooks, no roles.** Each host has its own playbook directory rather than shared Ansible roles. This made iteration faster during initial setup but means there is some duplication (swap setup, Docker install) across hosts. Roles would be the right refactor if a third or fourth host needed the same treatment.

**PostgreSQL on the VM, not in a container.** Running Postgres natively gives simpler backup configuration (pgBackRest to a NAS share) and avoids the complexity of persistent volumes in Docker. The API runs in a container on the same VM.

**RBAC gap.** `ansible/db-server/rbac.yml` sets up groups and roles but does not grant table/sequence privileges to `app_rw_grp`. Each new table needs a manual `GRANT` on the running instance until this is fixed.

**Keycloak stalled.** The Keycloak VM was provisioned and the install playbook was started, but the integration work was deprioritised in favour of the API migration. The `.stalled` extension on the Terraform file keeps it out of the active plan.

---

## Related repos

- [vb-manager-api](https://github.com/peixe-homedev/vb-manager-api) — FastAPI backend deployed by `ansible/db-server/deploy_api.yml`
- [vb-manager-app](https://github.com/peixe-homedev/vb-manager-app) — Streamlit frontend deployed by `ansible/app-server/app_deploy.yml`
