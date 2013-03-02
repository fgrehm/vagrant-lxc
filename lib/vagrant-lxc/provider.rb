require "vagrant-lxc/action"
require "vagrant-lxc/container"
require "vagrant-lxc/machine_state"

require "log4r"

module Vagrant
  module LXC
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :container

      def initialize(machine)
        @logger    = Log4r::Logger.new("vagrant::provider::lxc")
        @machine   = machine

        machine_id_changed
      end

      # If the machine ID changed, then we need to rebuild our underlying
      # container.
      def machine_id_changed
        id = @machine.id

        begin
          @logger.debug("Instantiating the container for: #{id.inspect}")
          @container = Container.new(id)
          @container.validate!
        rescue Container::NotFound
          # The container doesn't exist, so we probably have a stale
          # ID. Just clear the id out of the machine and reload it.
          @logger.debug("Container not found! Clearing saved machine ID and reloading.")
          id = nil
          retry
        end
      end

      # @see Vagrant::Plugin::V1::Provider#action
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        # TODO: Rename to singular
        return LXC::Action.send(action_method) if LXC::Action.respond_to?(action_method)
        nil
      end

      def state
        state_id = nil
        state_id = :not_created if !@container.name
        state_id = @container.state if !state_id
        state_id = :unknown if !state_id
        LXC::MachineState.new(state_id)
      end

      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "LXC (#{id})"
      end
    end
  end
end
