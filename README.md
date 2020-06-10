This builds a Vagrant [flatcar-linux](https://flatcar-linux.org/) Base Box.

# Usage

Install [Packer (1.6+)](https://www.packer.io/) and [Vagrant (2.2.9+)](https://www.vagrantup.com/).

If you are on a Debian/Ubuntu host, you should also install and configure the NFS server. E.g.:

```bash
# install the nfs server.
sudo apt-get install -y nfs-kernel-server

# enable password-less configuration of the nfs server exports.
sudo bash -c 'cat >/etc/sudoers.d/vagrant-synced-folders' <<'EOF'
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
EOF
```

For more information see the [Vagrant NFS documentation](https://www.vagrantup.com/docs/synced-folders/nfs.html).

## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
apt-get install -y rng-tools
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt # see https://github.com/vagrant-libvirt/vagrant-libvirt
vagrant up --provider=libvirt --no-destroy-on-error
vagrant ssh
exit
vagrant destroy -f
```

# Packer boot_command

The following table describes the steps used to install flatcar-linux.

**NB** This Packer `boot_command` method of installation is quite brittle, if you are having trouble installing, try increasing the install wait timeout.

| step                                   | boot_command                                                                    |
|---------------------------------------:|---------------------------------------------------------------------------------|
| switch to root                         | `sudo su -l<enter>`                                                             |
| configure the shell to abort on error  | `set -eu<enter>`                                                                |
| download the ignition configuration    | `wget -q http://{{.HTTPIP}}:{{.HTTPPort}}/tmp/ignition.json<enter><wait>`       |
| install to disk                        | `time flatcar-install -d /dev/sda -C stable -i ignition.json<enter>`            |
| wait 3m for the installation to finish | `<wait60><wait60><wait60>`                                                      |
| reboot to the installed system         | `reboot<enter>`                                                                 |

# Reference

* [Installing Flatcar Container Linux to disk](https://docs.flatcar-linux.org/os/installing-to-disk/)
* [Configuration Specification](https://docs.flatcar-linux.org/container-linux-config-transpiler/doc/configuration/)
