## Infrastruktura do rozdzialu Ansible w PDFie "77 Zadan dla Adminow"

Link do PDFu: https://77.mrugalski.pl/

---
### Opis:

Ponizszy kod terraforma pozwala w latwy i prosty sposob przygotowac infrastrukture
na potrzeby zadan w dziale Ansible.

Prosty schemat infrastruktury znajduje sie w pliku network_configure.drawio (mozna obejrzec za pomoca narzedzia http://draw.io)

Wymagania:
* serwer Proxmox
* podstawowa wiedza z terraforma
* wykonanie instrukcji ;)

OSTRZEZENIE: Obecna wersja zawiera instrukcje dla obrazu Debiana, a nie Ubuntu! (klania sie czytanie ze zrozumieniem ;) 

---
### Instrukcja:

1. Przygotowanie pliku z credentialami dla proxmoxa. W tym celu kopiujemy plik credentials.tmp do credentials.tf i nastepnie podmieniamy zmienna pm_user_x podajac usera + domene (np. "root@pam") oraz haslo jako wartosc zmiennej pm_pass_x.
2. Zmiana zmiennej var.clusteraddress podajac adres API waszego serwera Proxmoxa (domyslnie https://adres_ip:8006/api2/json)
3. Zmiana adresow IP i zasobow w tablicy ansible_vm znajdujacej sie w pliku variable.tf
3. Zalogowanie sie na serwer Proxmoxa i przygotowanie templatki z obrazem (podrozdzial Proxmox - Templatka VM)
4. Wygenerowanie kluczy ssh (na potrzeby polaczenia i "pregenerowania" fingerprintow - umila to zycie po rebuildach, gdy nie trzeba czyscic starego fingerprinta) 
    ```
    mkdir ssh_keys
    cd ssh_keys
    ssh-keygen -q -N "" -t ed25519 -f fingerprint_ed25519_key
    ssh-keygen -q -N "" -t rsa -f id_rsa
    ssh-keygen -q -N "" -t rsa -f fingerprint_rsa
    cd ..

5. W glownym folderze repo `terraform init`
6. W glownym folderze repo `terraform apply`

Aby skasowac terraformem powstala infrastrukture nalezy uzyc `terraform destroy`


---
### Proxmox - Templatka VM
1. Logujemy sie serwer Proxmoxa i wykonujemy (instrukcja utworzona dla Proxmox 7.3)
   Na potrzeby templatki zostal uzyty VMID 9000

```
cd /var/lib/vz/template/iso/

wget http://cdimage.debian.org/images/cloud/bullseye/20230124-1270/debian-11-generic-amd64-20230124-1270.qcow2

qm create 9000 -name debian-cloudinit -memory 1024 -net0 virtio,bridge=vmbr0 -cores 1 -sockets 1

qm importdisk 9000 debian-11-generic-amd64-20230124-1270.qcow2 local-lvm

qm set 9000 -scsihw virtio-scsi-pci -virtio0 local-lvm:vm-9000-disk-0

qm set 9000 -serial0 socket

qm set 9000 -boot c -bootdisk virtio0

qm set 9000 -agent 1

qm set 9000 -hotplug disk,network,usb

qm set 9000 -vcpus 1

qm set 9000 -vga qxl

qm set 9000 -ide2 local-lvm:cloudinit

qm resize 9000 virtio0 +8G

qm template 9000
```