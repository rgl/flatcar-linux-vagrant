VERSION=$(shell jq -r .variables.version flatcar-linux.json)

help:
	@echo type make build-libvirt

build-libvirt: flatcar-linux-${VERSION}-amd64-libvirt.box

flatcar-linux-${VERSION}-amd64-libvirt.box: tmp/ignition.json flatcar-linux.json Vagrantfile.template
	rm -f flatcar-linux-${VERSION}-amd64-libvirt.box
	CHECKPOINT_DISABLE=1 PACKER_KEY_INTERVAL=10ms PACKER_LOG=1 PACKER_LOG_PATH=$@-packer.log \
		packer build -only=flatcar-linux-${VERSION}-amd64-libvirt -on-error=abort flatcar-linux.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f flatcar-linux-${VERSION}-amd64 flatcar-linux-${VERSION}-amd64-libvirt.box

tmp/ignition.json: flatcar-linux-config.yml tmp/ct
	./tmp/ct --in-file flatcar-linux-config.yml >$@

tmp/ct:
	mkdir -p tmp
	wget -qO $@.tmp https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.9.0/ct-v0.9.0-x86_64-unknown-linux-gnu
	chmod +x $@.tmp
	mv $@.tmp $@

.PHONY: buid-libvirt
