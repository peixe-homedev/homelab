#!/bin/bash

# --- CONFIGURATION ---
VM_ID=9000
VM_NAME="almalinux-9-template"
STORAGE="local-lvm"
IMAGE_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
IMAGE_PATH="/var/lib/vz/template/iso/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"

# Ensure the target directory exists
mkdir -p "$(dirname "$IMAGE_PATH")"

echo "Checking for AlmaLinux 9 Cloud Image..."
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Downloading image to $IMAGE_PATH..."
    wget -q --show-progress -O "$IMAGE_PATH" "$IMAGE_URL"

    echo "Injecting QEMU Guest Agent into the fresh image..."
    virt-customize -a "$IMAGE_PATH" \
      --install qemu-guest-agent \
      --run-command 'systemctl enable qemu-guest-agent'
else
    echo "Image already exists. Skipping download and injection."
fi

echo "Destroying old template if it exists..."
qm destroy $VM_ID 2>/dev/null

echo "1. Creating VM Shell..."
qm create $VM_ID --name $VM_NAME --memory 1024 --cores 1 --cpu host --net0 virtio,bridge=vmbr0 --agent 1

echo "2. Importing Disk..."
qm importdisk $VM_ID "$IMAGE_PATH" $STORAGE

echo "3. Attaching Disk..."
# Note: Proxmox names the imported disk automatically, so we reference it here
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0

echo "4. Adding Cloud-Init drive..."
qm set $VM_ID --ide2 $STORAGE:cloudinit

echo "5. Setting Boot Order..."
qm set $VM_ID --boot order=scsi0

echo "6. Configuring Display..."
qm set $VM_ID --vga std

echo "7. Converting to Template..."
qm template $VM_ID

echo "DONE! Template $VM_ID is ready."
