# Orig source: https://yetiops.net/posts/proxmox-terraform-cloudinit-saltstack-prometheus/

# Transfer the file to the Proxmox Host
#resource "null_resource" "cloud_init_deb10_vm-01" {
#  connection {
#    type    = "ssh"
#    user    = "root"
#    private_key = file("~/.ssh/id_rsa")
#    host    = "192.168.1.230"
#  }

#  provisioner "file" {
#    source       = "cloudinit/storage-ci.yml"
#    destination  = "/var/lib/vz/snippets/storage-ci.yml"
#  }
#}

resource "proxmox_vm_qemu" "ansible_vms" {
# todo:
  ### 1. dorzucenie kluczy ssh do terraforma (aby moc sie lognac) (CHECK)
  ### 2. username - ansible (CHECK)

  ### Co potrzebuje, zeby to zrealizowac? terraform run-exec after creation (ew. provider nie posiada alternatywy)
  ### ODP: provisioner "remote-exec"
  ### 3. fqdn na poziomie maszynek (wpis do hostname per vmka)
  ### 4. dodatkowo plik /etc/hosts z wiedza o sobie nawzajem

  count = "5"

#  depends_on = [
#    null_resource.cloud_init_deb10_vm-01
#  ]

  #Proxmox settings
  vmid = "101" + count.index
  name = var.ansible_vm[count.index].fqdn
  target_node = "pve"

  #vm template
  clone = "debian-cloudinit"
  os_type = "cloud-init"

  #preprovision      = true #deprecated

  #ssh_user          = "ansible"
  #ssh_private_key   = file("${path.module}/ssh_keys/id_rsa")

  # Cloud init options
  ciuser = "ansible"
  cipassword = "ansible"
  #cicustom = "user=local:snippets/storage-ci.yml"
  sshkeys = file("${path.module}/ssh_keys/id_rsa.pub")
  ipconfig0 = "ip=${var.ansible_vm[count.index].ip}/24,gw=192.168.1.1"

  memory       = var.ansible_vm[count.index].ram
  #z powodu, ze obraz ktorego uzywam nie ma zainstalowanego qemu-guest-agenta domyslnie wylaczam poki co te opcje
  agent        = 0
  sockets       = 1
  cores         = 1

  # Set the boot disk paramters
  bootdisk = "scsi0"
  scsihw       = "virtio-scsi-pci"

  disk {
    #id              = 0
    size            = "10G"
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

  #todo: czy dzialaja tutaj kredki z cloudinitu?
  #      wczytuje, ale potrzebuje do komunikacji priv + publickey
  #
  connection {
    type        = "ssh"
    user        = "ansible"
    host        = var.ansible_vm[count.index].ip
    #password    = "ansible"
    private_key = file("${path.module}/ssh_keys/klucz_priv")
    port        = "22"
  }

   provisioner "remote-exec" {
    inline = [
      "sudo hostname ${var.ansible_vm[count.index].fqdn}"
      ]
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

