require 'vagrant-lxc/action/base_action'
require 'vagrant-lxc/action/handle_box_metadata'

# TODO: Split action classes into their own files
module Vagrant
  module LXC
    module Action
      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckLXC
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use VagrantPlugins::ProviderVirtualBox::Action::MessageNotCreated
              next
            end

            b2.use Vagrant::Action::Builtin::ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # We could do this here as VirtualBox does, but at least for now its better
      # to be explicit and have the full constant name in order to easily spot
      # what we implemented and what is builtin on Vagrant.
      #
      #   include Vagrant::Action::Builtin

      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use ClearForwardedPorts
          b.use Vagrant::Action::Builtin::Provision
          b.use Vagrant::Action::Builtin::EnvSet, :port_collision_repair => true
          b.use PrepareForwardedPortCollisionParams
          b.use ClearSharedFolders
          b.use ShareFolders
          b.use Network
          b.use ForwardPorts
          b.use HostName
          b.use SaneDefaults
          b.use Customize
          b.use Boot
        end
      end

      # This action starts a container, assuming it is already created and exists.
      # A precondition of this action is that the container exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckLXC
          b.use Vagrant::Action::Builtin::ConfigValidate
          b.use Vagrant::Action::Builtin::Call, IsRunning do |env, b2|
            # If the VM is running, then our work here is done, exit
            next if env[:result]
            # TODO: Check if has been saved / frozen and resume
            b2.use action_boot
          end
        end
      end

      # This action brings the machine up from nothing, including creating the
      # container, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckLXC
          b.use Vagrant::Action::Builtin::ConfigValidate
          b.use Vagrant::Action::Builtin::Call, Created do |env, b2|
            # If the VM is NOT created yet, then do the setup steps
            if !env[:result]
              b2.use HandleBoxMetadata
              b2.use Create
            end
          end
          b.use action_start
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckLXC
          b.use Vagrant::Action::Builtin::Call, Created do |env, b2|
            if env[:result]
              # TODO: If is paused, should resume and then halt
              # TODO: If could not gracefully halt, force it
              # TODO: b2.use Vagrant::Action::Builtin::GracefulHalt, :poweroff, :running
              unless env[:machine].state.off?
                puts 'TODO: Halt container using Vagrant::Action::Builtin::GracefulHalt'
                env[:machine].provider.container.halt
              end
            else
              b2.use VagrantPlugins::ProviderVirtualBox::Action::MessageNotCreated
            end
          end
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckLXC
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            # TODO: Implement our own DestroyConfirm or propose a builtin action for Vagrant core
            b2.use Vagrant::Action::Builtin::Call, VagrantPlugins::ProviderVirtualBox::Action::DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use Vagrant::Action::Builtin::ConfigValidate
                b3.use Vagrant::Action::Builtin::EnvSet, :force_halt => true
                b3.use action_halt
                b3.use Destroy
                # TODO: VirtualBox provider has a CleanMachineFolder action, do we need something similar?
                # TODO: VirtualBox provider has a DestroyUnusedNetworkInterfaces action, do we need something similar?
              else
                # TODO: Implement our own DestroyConfirm or propose a builtin action for Vagrant core
                b3.use VagrantPlugins::ProviderVirtualBox::Action::MessageWillNotDestroy
              end
            end
          end
        end
      end

      class Created < BaseAction
        def call(env)
          # Set the result to be true if the machine is created.
          env[:result] = env[:machine].state.created?

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end

      class IsRunning < BaseAction
        def call(env)
          # Set the result to be true if the machine is created.
          env[:result] = env[:machine].state.running?

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end

      class Create < BaseAction
        def call(env)
          machine_id       = env[:machine].provider.container.create(env[:machine].box.metadata)
          env[:machine].id = machine_id
          @app.call env
        end
      end

      class Destroy < BaseAction
        def call(env)
          env[:machine].provider.container.destroy
          env[:machine].id = nil
          @app.call env
        end
      end

      class Boot < BaseAction
        def call(env)
          env[:machine].provider.container.start
          @app.call env
        end
      end

      # TODO: Check if our requirements are met.
      class CheckLXC < BaseAction; end

      # TODO: Implement folder sharing with "mount"
      class ShareFolders < BaseAction; end

      # TODO: Sets up all networking for the container instance. This includes
      # host only networks, bridged networking, forwarded ports, etc.
      class Network < BaseAction; end

      # TODO: Implement port forwarding with rinetd
      class ForwardPorts < BaseAction; end

      # TODO: Find out which defaults are sane for LXC ;)
      class SaneDefaults < BaseAction; end

      # TODO: Find out if the actions below will be needed
      class ClearForwardedPorts < BaseAction; end
      class PrepareForwardedPortCollisionParams < BaseAction; end
      class ClearSharedFolders < BaseAction; end
      class HostName < BaseAction; end
      class Customize < BaseAction; end
    end
  end
end
