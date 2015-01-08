require "log4r"

require "vagrant-lxc/action"
require "vagrant-lxc/driver"
require "vagrant-lxc/sudo_wrapper"

module Vagrant
  module LXC
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def self.usable?(raise_error=false)
        if !Vagrant::Util::Platform.linux?
          raise Errors::LxcLinuxRequired
        end

        true
      end

      def initialize(machine)
        @logger    = Log4r::Logger.new("vagrant::provider::lxc")
        @machine   = machine

        ensure_lxc_installed!
        machine_id_changed
      end

      def sudo_wrapper
        @shell ||= begin
          wrapper = Pathname.new(LXC.sudo_wrapper_path).exist? &&
            LXC.sudo_wrapper_path || nil
          @logger.debug("Found sudo wrapper : #{wrapper}") if wrapper
          SudoWrapper.new(wrapper)
        end
      end

      def ensure_lxc_installed!
        begin
          sudo_wrapper.run("/usr/bin/which", "lxc-create")
        rescue Vagrant::LXC::Errors::ExecuteError
          raise Errors::LxcNotInstalled
        end
      end

      # If the machine ID changed, then we need to rebuild our underlying
      # container.
      def machine_id_changed
        id = @machine.id

        begin
          @logger.debug("Instantiating the container for: #{id.inspect}")
          @driver = Driver.new(id, self.sudo_wrapper)
          @driver.validate!
        rescue Driver::ContainerNotFound
          # The container doesn't exist, so we probably have a stale
          # ID. Just clear the id out of the machine and reload it.
          @logger.debug("Container not found! Clearing saved machine ID and reloading.")
          id = nil
          retry
        end
      end

      # @see Vagrant::Plugin::V2::Provider#action
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return LXC::Action.send(action_method) if LXC::Action.respond_to?(action_method)
        nil
      end

      # Returns the SSH info for accessing the Container.
      def ssh_info
        # If the Container is not running then we cannot possibly SSH into it, so
        # we return nil.
        return nil if state.id != :running

        # Run a custom action called "ssh_ip" which does what it says and puts
        # the IP found into the `:machine_ip` key in the environment.
        env = @machine.action("ssh_ip")

        # If we were not able to identify the container's IP, we return nil
        # here and we let Vagrant core deal with it ;)
        return nil unless env[:machine_ip]

        {
          :host => env[:machine_ip],
          :port => @machine.config.ssh.guest_port
        }
      end

      def state
        state_id = nil
        state_id = :not_created if !@driver.container_name
        state_id = @driver.state if !state_id
        state_id = :unknown if !state_id

        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("vagrant.commands.status.#{state_id}")

        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "LXC (#{id})"
      end
    end
  end
end
