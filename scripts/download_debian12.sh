#!/bin/bash

# Update the local appliance database
echo "Updating Proxmox appliance database..."
pveam update

# Find the latest Debian 12 standard template filename
TEMPLATE=$(pveam available --section system | grep "debian-12-standard" | awk '{print $2}' | head -n 1)

if [ -z "$TEMPLATE" ]; then
    echo "Error: Could not find a Debian 12 standard template."
    exit 1
fi

echo "Found latest template: $TEMPLATE"

# Download to the 'local' storage
echo "Downloading $TEMPLATE to local storage..."
pveam download local "$TEMPLATE"

echo "Done! Use this filename in your Terraform template_file_id: local:vztmpl/$TEMPLATE"