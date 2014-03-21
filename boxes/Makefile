UBUNTU_BOXES= precise quantal raring saucy trusty
DEBIAN_BOXES= squeeze wheezy sid jessie
TODAY=$(shell date -u +"%Y-%m-%d")

default:

all: ubuntu debian

ubuntu: $(UBUNTU_BOXES)
debian: $(DEBIAN_BOXES)

# REFACTOR: Figure out how can we reduce duplicated code
$(UBUNTU_BOXES): CONTAINER = "vagrant-base-${@}-amd64"
$(UBUNTU_BOXES): PACKAGE = "output/${TODAY}/vagrant-lxc-${@}-amd64.box"
$(UBUNTU_BOXES):
	@mkdir -p $$(dirname $(PACKAGE))
	@sudo -E ./mk-debian.sh ubuntu $(@) amd64 $(CONTAINER) $(PACKAGE)
	@sudo chmod +rw $(PACKAGE)
	@sudo chown ${USER}: $(PACKAGE)
$(DEBIAN_BOXES): CONTAINER = "vagrant-base-${@}-amd64"
$(DEBIAN_BOXES): PACKAGE = "output/${TODAY}/vagrant-lxc-${@}-amd64.box"
$(DEBIAN_BOXES):
	@mkdir -p $$(dirname $(PACKAGE))
	@sudo -E ./mk-debian.sh debian $(@) amd64 $(CONTAINER) $(PACKAGE)
	@sudo chmod +rw $(PACKAGE)
	@sudo chown ${USER}: $(PACKAGE)

acceptance: CONTAINER = "vagrant-base-acceptance-amd64"
acceptance: PACKAGE = "output/${TODAY}/vagrant-lxc-acceptance-amd64.box"
acceptance:
	@mkdir -p $$(dirname $(PACKAGE))
	@PUPPET=1 CHEF=1 sudo -E ./mk-debian.sh ubuntu precise amd64 $(CONTAINER) $(PACKAGE)
	@sudo chmod +rw $(PACKAGE)
	@sudo chown ${USER}: $(PACKAGE)

clean: ALL_BOXES = ${DEBIAN_BOXES} ${UBUNTU_BOXES} acceptance
clean:
	@for r in $(ALL_BOXES); do \
		sudo -E ./clean.sh $${r}\
		                   vagrant-base-$${r}-amd64 \
				               output/${TODAY}/vagrant-lxc-$${r}-amd64.box; \
		done
