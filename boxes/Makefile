UBUNTU_BOXES= precise quantal raring saucy trusty
DEBIAN_BOXES= squeeze wheezy sid jessie
TODAY=$(shell date -u +"%Y-%m-%d")

default:

all: ubuntu debian

ubuntu: $(UBUNTU_BOXES)
debian: $(DEBIAN_BOXES)

# REFACTOR: Figure out how can we reduce duplicated code
$(UBUNTU_BOXES): CONTAINER = "vagrant-lxc-base-${@}-amd64"
$(UBUNTU_BOXES): PACKAGE = "output/${TODAY}/vagrant-lxc-${@}-amd64.box"
$(UBUNTU_BOXES):
	@mkdir -p $$(dirname $(PACKAGE))
	@sudo -E ./mk-debian.sh ubuntu $(@) amd64 $(CONTAINER) $(PACKAGE)
	@sudo chmod +rw $(PACKAGE)
	@sudo chown ${USER}: $(PACKAGE)
$(DEBIAN_BOXES): CONTAINER = "vagrant-lxc-base-${@}-amd64"
$(DEBIAN_BOXES): PACKAGE = "output/${TODAY}/vagrant-lxc-${@}-amd64.box"
$(DEBIAN_BOXES):
	@mkdir -p $$(dirname $(PACKAGE))
	@sudo -E ./mk-debian.sh debian $(@) amd64 $(CONTAINER) $(PACKAGE)
	@sudo chmod +rw $(PACKAGE)
	@sudo chown ${USER}: $(PACKAGE)

clean: ALL_BOXES = ${DEBIAN_BOXES} ${UBUNTU_BOXES}
clean:
	@for r in $(ALL_BOXES); do \
		sudo -E ./clean.sh $${r}\
		                   vagrant-lxc-base-$${r}-amd64 \
				               output/${TODAY}/vagrant-lxc-$${r}-amd64-${TODAY}.box; \
		done
