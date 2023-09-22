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
  default = "3033.2.4"
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
  default = "https://stable.release.flatcar-linux.net/amd64-usr/3033.2.4/flatcar_production_iso_image.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha512:f0b0a8d35e4dfa98ae0ab7f751868f28e75147630d92047cbe32036e5ede3d4dff958d2976eae6e24d33f4f5b3b72685c54b06d23447457900a3b97edb7a87cb"
}

variable "disk_size" {
  type    = string
  default = 20 * 1024
}

source "qemu" "flatcar-linux" {
  accelerator  = "kvm"
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

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
