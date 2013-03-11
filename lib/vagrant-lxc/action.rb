require 'vagrant-lxc/action/base_action'

require 'vagrant-lxc/action/boot'
require 'vagrant-lxc/action/check_created'
require 'vagrant-lxc/action/check_running'
require 'vagrant-lxc/action/create'
require 'vagrant-lxc/action/created'
require 'vagrant-lxc/action/destroy'
require 'vagrant-lxc/action/forced_halt'
require 'vagrant-lxc/action/handle_box_metadata'
require 'vagrant-lxc/action/is_running'
require 'vagrant-lxc/action/network'
require 'vagrant-lxc/action/share_folders'

module Vagrant
  module LXC
    module Action
      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          # b.use CheckLXC
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
          # b.use ClearForwardedPorts
          b.use Vagrant::Action::Builtin::Provision
          b.use Vagrant::Action::Builtin::EnvSet, :port_collision_repair => true
          # b.use PrepareForwardedPortCollisionParams
          # b.use ClearSharedFolders
          b.use ShareFolders
          b.use Network
          # b.use ForwardPorts
          # b.use SaneDefaults
          # b.use Customize
          b.use Boot
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          # b.use CheckLXC
          b.use Vagrant::Action::Builtin::ConfigValidate
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use VagrantPlugins::ProviderVirtualBox::Action::MessageNotCreated
              next
            end

            b2.use Vagrant::Action::Builtin::Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use VagrantPlugins::ProviderVirtualBox::Action::MessageNotRunning
                next
              end

              # b3.use CheckAccessible
              b3.use Vagrant::Action::Builtin::Provision
            end
          end
        end
      end

      # This action starts a container, assuming it is already created and exists.
      # A precondition of this action is that the container exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          # b.use CheckLXC
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
          # b.use CheckLXC
          b.use Vagrant::Action::Builtin::ConfigValidate
          b.use Vagrant::Action::Builtin::Call, Created do |env, b2|
            # If the VM is NOT created yet, then do the setup steps
            if !env[:result]
              b2.use Vagrant::Action::Builtin::HandleBoxUrl
              b2.use HandleBoxMetadata
              b2.use Create
            end
          end
          b.use action_start
          # b.use Vagrant::Action::Builtin::SetHostname
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          # b.use CheckLXC
          b.use Vagrant::Action::Builtin::Call, Created do |env, b2|
            if env[:result]
              b2.use Vagrant::Action::Builtin::Call, Vagrant::Action::Builtin::GracefulHalt, :stopped, :running do |env2, b3|
                if !env2[:result] && env2[:machine].provider.state.running?
                  b3.use ForcedHalt
                end
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
          # b.use CheckLXC
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use VagrantPlugins::ProviderVirtualBox::Action::MessageNotCreated
              next
            end

            # TODO: Implement our own DestroyConfirm
            b2.use Vagrant::Action::Builtin::Call, VagrantPlugins::ProviderVirtualBox::Action::DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use Vagrant::Action::Builtin::ConfigValidate
                b3.use Vagrant::Action::Builtin::EnvSet, :force_halt => true
                b3.use action_halt
                b3.use Destroy
                # TODO: VirtualBox provider has a CleanMachineFolder action, do we need something similar?
                # TODO: VirtualBox provider has a DestroyUnusedNetworkInterfaces action, do we need something similar?
              else
                # TODO: Implement our own MessageWillNotDestroy
                b3.use VagrantPlugins::ProviderVirtualBox::Action::MessageWillNotDestroy
              end
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          # b.use CheckLXC
          b.use CheckCreated
          # b.use CheckAccessible
          b.use CheckRunning
          b.use Vagrant::Action::Builtin::SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          # b.use CheckLXC
          b.use CheckCreated
          # b.use CheckAccessible
          b.use CheckRunning
          b.use Vagrant::Action::Builtin::SSHRun
        end
      end
    end
  end
end
