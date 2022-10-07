FLATCAR_CHANNEL = stable
OPENNEBULA_DATASTORE = default

PACKER_IMAGE_DIR = builds/flatcar-$(FLATCAR_CHANNEL)-qemu
PACKER_IMAGE_NAME = flatcar-$(FLATCAR_CHANNEL)
PACKER_IMAGE = $(PACKER_IMAGE_DIR)/$(PACKER_IMAGE_NAME)
PACKER_IMAGE_BZ2 = $(PACKER_IMAGE).bz2
PACKER_IMAGE_DEPS = \
	flatcar.pkr.hcl \
	packer.sh \
	files/install.yml \
	oem/flatcar-setup-environment \
	oem/opennebula-cloudinit \
	oem/opennebula-common \
	oem/opennebula-hostname \
	oem/opennebula-network \
	oem/opennebula-ssh-key \
	scripts/cleanup.sh \
	scripts/oem.sh

all: $(PACKER_IMAGE)

$(PACKER_IMAGE): $(PACKER_IMAGE_DEPS)
	rm -rf $(PACKER_IMAGE_DIR)
	env \
	  FLATCAR_CHANNEL=$(FLATCAR_CHANNEL) \
	  PACKER_LOG=1 \
	    ./packer.sh validate flatcar.pkr.hcl
	env \
	  FLATCAR_CHANNEL=$(FLATCAR_CHANNEL) \
	  PACKER_LOG=1 \
	    ./packer.sh build flatcar.pkr.hcl
	mv $(PACKER_IMAGE_DIR)/packer-flatcar $(PACKER_IMAGE)
	bzip2 -9vk $(PACKER_IMAGE)
	echo "Image file $(PACKER_IMAGE) ready"

.PHONY: appliance register clean

OPENNEBULA_IMAGE = flatcar-$(FLATCAR_CHANNEL)

register: $(PACKER_IMAGE)
	-oneimage delete $(OPENNEBULA_IMAGE)
	oneimage create \
	  --name $(OPENNEBULA_IMAGE) \
	  --description "Flatcar Linux $(FLATCAR_CHANNEL)" \
	  --type OS \
	  --driver qcow2 \
	  --datastore $(OPENNEBULA_DATASTORE) \
	  --path $(PACKER_IMAGE)
	echo "EC2_AMI=YES" > .ec2_attrs
	oneimage update $(OPENNEBULA_IMAGE) --append .ec2_attrs
	rm -f .ec2_attrs

appliance: $(PACKER_IMAGE)
	./generate-appliance-json.py \
	  --output appliance.json \
	  $(FLATCAR_CHANNEL) \
	  $(PACKER_IMAGE).bz2 \
	  $(IMAGE_URL)

clean:
	rm -rf builds
