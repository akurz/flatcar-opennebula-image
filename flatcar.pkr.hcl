variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "boot_wait" {
  type    = string
  default = "60s"
}

variable "flatcar_channel" {
  type    = string
  default = "stable"
}

variable "flatcar_version" {
  type = string
}
variable "iso_checksum" {
  type = string
}
variable "iso_checksum_type" {
  type    = string
  default = "md5"
}

variable "headless" {
  type    = string
  default = "false"
}

variable "disk_interface" {
  type    = string
  default = "virtio"
}

variable "install_target" {
  type    = string
  default = "/dev/vda"
}

variable "memory" {
  type    = number
  default = 2048
}

variable "cpus" {
  type    = number
  default = 1
}

variable "net_device" {
  type    = string
  default = "virtio-net"
}

variable "autologin" {
  type    = string
  default = "false"
}

variable "selinux_enabled" {
  type    = string
  default = "false"
}

packer {
  required_version = ">= 1.8.3, < 2.0.0"
  required_plugins {
    qemu = {
      version = "~> 1.0.6"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "flatcar" {
  accelerator = "${var.accelerator}"
  cpus        = "${var.cpus}"
  memory      = "${var.memory}"
  net_device  = "${var.net_device}"
  boot_wait   = "${var.boot_wait}"
  boot_command = [
    "sudo -i<enter>",
    "systemctl stop sshd.socket<enter>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.yml<enter>",
    "coreos-install -d ${var.install_target} -C ${var.flatcar_channel} -c install.yml<enter>",
    "reboot<enter>"
  ]
  communicator         = "ssh"
  disk_interface       = "${var.disk_interface}"
  disk_size            = "10G"
  headless             = "${var.headless}"
  http_directory       = "files"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url              = "https://${var.flatcar_channel}.release.flatcar-linux.net/amd64-usr/${var.flatcar_version}/flatcar_production_iso_image.iso"
  format               = "qcow2"
  output_directory     = "builds/flatcar-${var.flatcar_channel}-qemu"
  shutdown_command     = "sudo -S shutdown -P now"
  ssh_private_key_file = "files/vagrant_id_rsa"
  ssh_timeout          = "60m"
  ssh_username         = "core"
}

build {
  description = "Flatcar Linux image for OpenNebula"

  sources = ["source.qemu.flatcar"]

  provisioner "file" {
    destination = "/home/core"
    source      = "oem/"
  }

  provisioner "shell" {
    scripts = ["scripts/oem.sh", "scripts/cleanup.sh"]
  }

  provisioner "shell" {
    environment_vars = [
      "AUTOLOGIN=${var.autologin}"
      "SELINUX=${var.selinux_enabled}"
    ]
    scripts = ["scripts/grub.sh"]
  }

}
