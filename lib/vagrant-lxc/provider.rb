require "vagrant-lxc/machine_state"

require "log4r"

module Vagrant
  module LXC
    # DISCUSS: VirtualBox provider has a #machine_id_changed, do we need to handle it as well?
    class Provider < Vagrant.plugin("2", :provider)
      def initialize(machine)
        @logger  = Log4r::Logger.new("vagrant::provider::lxc")
        @machine = machine
      end

      def state
        LXC::MachineState.new(@machine)
      end

      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "LXC (#{id})"
      end
    end
  end
end
