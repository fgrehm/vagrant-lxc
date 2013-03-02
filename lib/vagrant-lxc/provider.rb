require "vagrant-lxc/actions"
require "vagrant-lxc/container"
require "vagrant-lxc/machine_state"

require "log4r"

module Vagrant
  module LXC
    # DISCUSS: VirtualBox provider has a #machine_id_changed, do we need to handle it as well?
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :container

      def initialize(machine)
        @logger    = Log4r::Logger.new("vagrant::provider::lxc")
        @machine   = machine
        @container = Container.new(@machine.id)
      end

      # @see Vagrant::Plugin::V1::Provider#action
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        # TODO: Rename to singular
        return LXC::Actions.send(action_method) if LXC::Actions.respond_to?(action_method)
        nil
      end

      def state
        LXC::MachineState.new(@container.state)
      end

      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "LXC (#{id})"
      end
    end
  end
end
