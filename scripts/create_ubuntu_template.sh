#!/bin/bash

# --- CONFIGURATION ---
VM_ID=9001
VM_NAME="ubuntu-2404-template"
STORAGE="local-lvm"
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_PATH="/var/lib/vz/template/iso/noble-server-cloudimg-amd64.img"

# Ensure the target directory exists
mkdir -p "$(dirname "$IMAGE_PATH")"

# --- 0. DOWNLOAD & CUSTOMIZE IMAGE ---
echo "0. Checking for Ubuntu 24.04 Cloud Image..."
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Downloading image to $IMAGE_PATH..."
    wget -q --show-progress -O "$IMAGE_PATH" "$IMAGE_URL"
    
    echo "0.5 Injecting qemu-guest-agent and fixing DNS symlink..."
    # Note: Added machine-id truncate and cloud-init clean for uniqueness
    virt-customize -a "$IMAGE_PATH" \
    --install qemu-guest-agent \
    --run-command 'systemctl enable systemd-resolved' \
    --run-command 'rm -f /etc/resolv.conf && ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf' \
    --truncate /etc/machine-id \
    --run-command 'cloud-init clean'
else
    echo "Image already exists. Skipping download."
fi

echo "Destroying old template if it exists..."
qm destroy $VM_ID 2>/dev/null

# --- 1. CREATE VM ---
echo "1. Creating VM Shell..."
# Fixed: --agent 1 is changed to --agent enabled=1 in modern qm
qm create $VM_ID --name $VM_NAME --memory 2048 --cores 2 --cpu host --net0 virtio,bridge=vmbr0 --agent enabled=1

# --- 2. IMPORT & ATTACH OS DISK ---
echo "2-3. Importing and Attaching OS Disk..."
# Combined: Using 'import-from' is the modern, one-step way to import and attach
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 "$STORAGE:0,import-from=$IMAGE_PATH"

# --- 4. ADD CLOUD-INIT ---
echo "4. Adding Cloud-Init drive..."
qm set $VM_ID --ide2 $STORAGE:cloudinit

# --- 5. SET BOOT ORDER ---
echo "5. Setting Boot Order..."
qm set $VM_ID --boot order=scsi0

# --- 6. CONFIGURE DISPLAY & SERIAL ---
echo "6. Configuring Display..."
qm set $VM_ID --vga std

# --- 7. RESIZE OS DISK ---
echo "7. Resizing OS Disk to 15G..."
qm resize $VM_ID scsi0 15G

# --- 8. CONVERT TO TEMPLATE ---
echo "8. Converting to Template..."
qm template $VM_ID

echo "DONE! Template $VM_ID is ready with the Guest Agent baked in."