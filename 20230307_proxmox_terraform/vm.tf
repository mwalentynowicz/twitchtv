# Orig source: https://yetiops.net/posts/proxmox-terraform-cloudinit-saltstack-prometheus/

# Transfer the file to the Proxmox Host
resource "null_resource" "cloud_init_deb10_vm-01" {
  connection {
    type    = "ssh"
    user    = "root"
    private_key = file("~/.ssh/id_rsa")
    host    = "192.168.1.230"
  }

  provisioner "file" {
    source       = "cloudinit/storage-ci.yml"
    destination  = "/var/lib/vz/snippets/storage-ci.yml"
  }
}

# Create the VM
resource "proxmox_vm_qemu" "storage-01" {
  ## Wait for the cloud-config file to exist

  depends_on = [
    null_resource.cloud_init_deb10_vm-01
  ]

  name = "storage-01"
  target_node = "pve"

  # Clone from debian-cloudinit template
  clone = "debian-cloudinit"
  os_type = "cloud-init"

  # Cloud init options
  cicustom = "user=local:snippets/storage-ci.yml"
  ipconfig0 = "ip=192.168.1.231/24,gw=192.168.1.1"

  memory       = 2048
  agent        = 1
  sockets       = 2
  cores         = 1

  # Set the boot disk paramters
  bootdisk = "scsi0"
  scsihw       = "virtio-scsi-pci"

  disk {
    #id              = 0
    size            = "80G"
    type            = "scsi"
    storage         = "local-lvm"
    #storage_type    = "lvm"
    #iothread        = true
  }

  # Set the network
  network {
    #id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  # Ignore changes to the network
  ## MAC address is generated on every apply, causing
  ## TF to think this needs to be rebuilt on every apply
  lifecycle {
     ignore_changes = [
       network
     ]
  }
}

