packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "1.0.9"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "1.0.3"
    }
  }
}

variable "version" {
  type    = string
  default = "3510.2.8"
}

variable "vagrant_box" {
  type = string
}

variable "channel" {
  type    = string
  default = "stable"
}

variable "iso_url" {
  type    = string
  default = "https://stable.release.flatcar-linux.net/amd64-usr/3510.2.8/flatcar_production_iso_image.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha512:508862c9fb5e556d251fdb25b6b1628810efd3f3ce78b13feefa2353a3245523dad6aaba6e854bddbe9dd600d53abd2fe98665f57881e292c01f7016922dcab5"
}

variable "disk_size" {
  type    = string
  default = 20 * 1024
}

source "qemu" "flatcar-linux" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 4
  memory       = 4 * 1024
  qemuargs = [
    ["-cpu", "host"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-object", "rng-random,filename=/dev/urandom,id=rng0"],
    ["-device", "virtio-rng-pci,rng=rng0"],
  ]
  boot_wait = "2m"
  boot_command = [
    "sudo -i<enter>",
    "set -eu<enter>",
    "wget -q http://{{.HTTPIP}}:{{.HTTPPort}}/tmp/ignition.json<enter><wait>",
    "time flatcar-install -d /dev/sda -C ${var.channel} -i ignition.json<enter>",
    "<wait3m>",
    "reboot<enter>"
  ]
  net_device       = "virtio-net"
  disk_interface   = "virtio-scsi"
  disk_cache       = "unsafe"
  disk_discard     = "unmap"
  disk_size        = var.disk_size
  format           = "qcow2"
  headless         = true
  http_directory   = "."
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  ssh_password     = "core"
  ssh_username     = "core"
  ssh_wait_timeout = "60m"
  shutdown_command = "sudo poweroff"
}

build {
  sources = [
    "source.qemu.flatcar-linux"
  ]

  provisioner "shell" {
    execute_command = "sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "provision-sysprep.sh",
    ]
  }

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
