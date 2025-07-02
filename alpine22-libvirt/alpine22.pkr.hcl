packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "alpine" {
  iso_url            = "https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86_64/alpine-standard-3.22.0-x86_64.iso"
  iso_checksum       = "sha256:08283b76f95c0828f51c03ade5690eb4a4bda8e1c86f57567ae8cedaf4f04aae"
  output_directory   = "output-alpine22"
  accelerator        = "kvm"
  disk_size          = "5120M"
  format             = "qcow2"

  communicator     = "ssh"
  ssh_username     = "root"
  ssh_password     = "root"
  ssh_agent_auth   = false
  ssh_wait_timeout = "20m"

  shutdown_command = "poweroff"

  boot_wait = "10s"  # espera 10s tras el arranque antes de teclear

  boot_command = [
    "<enter>",                      # aceptar el prompt de boot
    "root<enter>",                  # login como root
    "sleep 3<enter>",               # deja unos segundos para que cargue el shell

    # Ahora sí: configurar repos
    "echo 'https://dl-cdn.alpinelinux.org/alpine/v3.22/main' > /etc/apk/repositories<enter>",
    "echo 'https://dl-cdn.alpinelinux.org/alpine/v3.22/community' >> /etc/apk/repositories<enter>",

    # Red y DHCP
    "ifconfig eth0 up<enter>",
    "udhcpc -i eth0<enter>",

    # Instalación y SSH
    "apk update<enter>",
    "apk add openrc openssh sudo<enter>",
    "sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config<enter>",
    "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config<enter>",
    "rc-update add sshd default<enter>",
    "rc-service sshd start<enter>",

    # Usuario vagrant
    "echo 'root:root' | chpasswd<enter>",
    "adduser -D -G wheel vagrant<enter>",
    "echo 'vagrant:vagrant' | chpasswd<enter>",
    "echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers<enter>"
    # <— No poweroff aquí: Packer usará tu shutdown_command
  ]
  vm_name = "alpine22"
}

build {
  sources = ["source.qemu.alpine"]
}


