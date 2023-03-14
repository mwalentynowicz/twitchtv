* log on proxmox server
* apt-get install libguestfs-tools
* cd /var/lib/vz/template/iso/
* wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
* virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent
* virt-customize -a jammy-server-cloudimg-amd64.img --run-command "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
* qm create 9001 --memory 2048 --net0 virtio,bridge=vmbr0
* qm importdisk 9001 jammy-server-cloudimg-amd64.img local-lvm
* qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
* qm set 9001 --agent enabled=1,fstrim_cloned_disks=1
* qm set 9001 --name ubuntu-cloudinit-template
* qm set 9001 --ide2 local-lvm:cloudinit
* qm set 9001 --boot c --bootdisk scsi0
* qm set 9001 --serial0 socket --vga serial0
* qm resize 9001 scsi +8G
* qm template 9001