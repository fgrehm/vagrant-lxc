UBUNTU_BOXES= precise quantal raring saucy trusty
TODAY=$(shell date -u +"%Y-%m-%d")

default:

all: $(UBUNTU_BOXES)

$(UBUNTU_BOXES): CONTAINER = "vagrant-lxc-base-${@}-amd64-${TODAY}"
$(UBUNTU_BOXES): PACKAGE = "output/$(CONTAINER).box"
$(UBUNTU_BOXES):
	@sudo -E ./mk-ubuntu.sh $(@) amd64 $(CONTAINER) $(PACKAGE)

clean:
	@echo "Implement clean"
	@exit 1
