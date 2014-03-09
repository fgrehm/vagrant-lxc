UBUNTU_BOXES= precise quantal raring saucy trusty
TODAY=$(shell date -u +"%Y-%m-%d")

default:

all: $(UBUNTU_BOXES)

$(UBUNTU_BOXES): CONTAINER = "vagrant-lxc-base-${@}-amd64-${TODAY}"
$(UBUNTU_BOXES): PACKAGE = "output/vagrant-lxc-${@}-amd64-${TODAY}.box"
$(UBUNTU_BOXES):
	@sudo -E ./mk-ubuntu.sh $(@) amd64 $(CONTAINER) $(PACKAGE)
	@sudo chmod +rw $(PACKAGE)
	@sudo chown ${USER}: $(PACKAGE)

clean:
	@for r in $(UBUNTU_BOXES); do \
		sudo -E ./clean.sh $${r}\
		                   vagrant-lxc-base-$${r}-amd64-${TODAY} \
				               output/vagrant-lxc-$${r}-amd64-${TODAY}.box; \
		done
