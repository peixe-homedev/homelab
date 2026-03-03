#!/bin/bash
# --- CONFIGURATION ---
VM_ID=9002
VM_NAME="debian-12-template"
STORAGE="local-lvm"
IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
IMAGE_PATH="/var/lib/vz/template/iso/debian-12-generic-amd64.qcow2"

mkdir -p "$(dirname "$IMAGE_PATH")"

echo "0. Downloading & Customizing Image..."
if [ ! -f "$IMAGE_PATH" ]; then
    wget -q --show-progress -O "$IMAGE_PATH" "$IMAGE_URL"
    # Bake the agent in AND ensure it starts
    virt-customize -a "$IMAGE_PATH" \
    --install qemu-guest-agent,cifs-utils \
    --run-command 'systemctl enable qemu-guest-agent' \
    --truncate /etc/machine-id
fi

qm destroy $VM_ID 2>/dev/null

echo "1. Creating VM Shell..."
# We add 'fstrim_cloned_disks' which helps the agent sync after a clone
qm create $VM_ID --name $VM_NAME --memory 2048 --cores 2 --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-single \
  --agent enabled=1

echo "2. Importing Disk..."
qm set $VM_ID --scsi0 "$STORAGE:0,import-from=$IMAGE_PATH,discard=on,ssd=1"

# 3. Cloud-Init on SCSI 1 (Avoids IDE bus conflicts)
qm set $VM_ID --scsi1 $STORAGE:cloudinit

# 4. Display
qm set $VM_ID --vga std --serial0 socket

# 5. Boot
qm set $VM_ID --boot order=scsi0

# 6. Template
echo "5. Converting to Template..."
qm template $VM_ID