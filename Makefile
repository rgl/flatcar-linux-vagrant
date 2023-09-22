SHELL=bash
.SHELLFLAGS=-euo pipefail -c

# see https://www.flatcar.org/releases
# see https://stable.release.flatcar-linux.net/amd64-usr/
VERSION=3510.2.8

help:
	@echo type make build-libvirt

build-libvirt: flatcar-linux-${VERSION}-amd64-libvirt.box

flatcar-linux-${VERSION}-amd64-libvirt.box: tmp/ignition.json flatcar-linux.pkr.hcl Vagrantfile.template
	rm -f flatcar-linux-${VERSION}-amd64-libvirt.box
	CHECKPOINT_DISABLE=1 \
	PACKER_KEY_INTERVAL=10ms \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@-packer.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.flatcar-linux -on-error=abort -timestamp-ui flatcar-linux.pkr.hcl
	@./box-metadata.sh libvirt flatcar-linux-${VERSION}-amd64 $@

tmp/ignition.json: flatcar-linux-config.yml tmp/ct
	./tmp/ct --in-file flatcar-linux-config.yml >$@

tmp/ct:
	mkdir -p tmp
	wget -qO $@.tmp https://github.com/flatcar-linux/container-linux-config-transpiler/releases/download/v0.9.3/ct-v0.9.3-x86_64-unknown-linux-gnu
	chmod +x $@.tmp
	mv $@.tmp $@

.PHONY: buid-libvirt
