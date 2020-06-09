VERSION=$(shell jq -r .variables.version flatcar-linux.json)

help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: flatcar-linux-${VERSION}-amd64-libvirt.box

flatcar-linux-${VERSION}-amd64-libvirt.box: answers provision.sh flatcar-linux.json Vagrantfile.template
	rm -f flatcar-linux-${VERSION}-amd64-libvirt.box
	CHECKPOINT_DISABLE=1 PACKER_KEY_INTERVAL=10ms PACKER_LOG=1 PACKER_LOG_PATH=$@-packer.log \
		packer build -only=flatcar-linux-${VERSION}-amd64-libvirt -on-error=abort flatcar-linux.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f flatcar-linux-${VERSION}-amd64 flatcar-linux-${VERSION}-amd64-libvirt.box

.PHONY: buid-libvirt
