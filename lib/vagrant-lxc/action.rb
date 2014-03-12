require 'vagrant-lxc/action/boot'
require 'vagrant-lxc/action/check_created'
require 'vagrant-lxc/action/check_running'
require 'vagrant-lxc/action/clear_forwarded_ports'
require 'vagrant-lxc/action/create'
require 'vagrant-lxc/action/created'
require 'vagrant-lxc/action/destroy'
require 'vagrant-lxc/action/destroy_confirm'
require 'vagrant-lxc/action/disconnect'
require 'vagrant-lxc/action/compress_rootfs'
require 'vagrant-lxc/action/fetch_ip_with_lxc_attach'
require 'vagrant-lxc/action/fetch_ip_from_dnsmasq_leases'
require 'vagrant-lxc/action/forced_halt'
require 'vagrant-lxc/action/forward_ports'
require 'vagrant-lxc/action/handle_box_metadata'
require 'vagrant-lxc/action/is_running'
require 'vagrant-lxc/action/message'
require 'vagrant-lxc/action/prepare_nfs_settings'
require 'vagrant-lxc/action/prepare_nfs_valid_ids'
require 'vagrant-lxc/action/remove_temporary_files'
require 'vagrant-lxc/action/setup_package_files'
require 'vagrant-lxc/action/warn_networks'

unless Vagrant::Backports.vagrant_1_3_or_later?
  require 'vagrant-backports/action/wait_for_communicator'
end
unless Vagrant::Backports.vagrant_1_5_or_later?
  require 'vagrant-backports/action/handle_box'
end

module Vagrant
  module LXC
    module Action
      # Shortcuts
      Builtin = Vagrant::Action::Builtin
      Builder = Vagrant::Action::Builder

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Builder.new.tap do |b|
          b.use Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Builtin::ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Builder.new.tap do |b|
          b.use Builtin::Provision
          b.use Builtin::EnvSet, :port_collision_repair => true
          b.use Builtin::HandleForwardedPortCollisions
          if Vagrant::Backports.vagrant_1_4_or_later?
            b.use PrepareNFSValidIds
            b.use Builtin::SyncedFolderCleanup
            b.use Builtin::SyncedFolders
            b.use PrepareNFSSettings
          else
            require 'vagrant-lxc/backports/action/share_folders'
            b.use ShareFolders
          end
          b.use Builtin::SetHostname
          b.use WarnNetworks
          b.use ForwardPorts
          b.use Boot
          b.use Builtin::WaitForCommunicator
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Builder.new.tap do |b|
          b.use Builtin::ConfigValidate
          b.use Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Builtin::Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use Message, :not_running
                next
              end

              b3.use Builtin::Provision
            end
          end
        end
      end

      # This action starts a container, assuming it is already created and exists.
      # A precondition of this action is that the container exists.
      def self.action_start
        Builder.new.tap do |b|
          b.use Builtin::ConfigValidate
          b.use Builtin::Call, IsRunning do |env, b2|
            # If the VM is running, then our work here is done, exit
            next if env[:result]
            b2.use action_boot
          end
        end
      end

      # This action brings the machine up from nothing, including creating the
      # container, configuring metadata, and booting.
      def self.action_up
        Builder.new.tap do |b|
          b.use Builtin::ConfigValidate
          b.use Builtin::Call, Created do |env, b2|
            # If the VM is NOT created yet, then do the setup steps
            if !env[:result]
              b2.use Builtin::HandleBox
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
        Builder.new.tap do |b|
          b.use Builtin::Call, Created do |env, b2|
            if env[:result]
              # TODO: Remove once we drop support for vagrant 1.1
              b2.use Disconnect
              b2.use ClearForwardedPorts
              b2.use RemoveTemporaryFiles
              b2.use Builtin::Call, Builtin::GracefulHalt, :stopped, :running do |env2, b3|
                if !env2[:result]
                  b3.use ForcedHalt
                end
              end
            else
              b2.use Message, :not_created
            end
          end
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Builder.new.tap do |b|
          b.use Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            # TODO: Use Vagrant's built in action once we drop support for vagrant 1.2
            b2.use Builtin::Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use Builtin::ConfigValidate
                b3.use Builtin::EnvSet, :force_halt => true
                b3.use action_halt
                b3.use Destroy
                if Vagrant::Backports.vagrant_1_3_or_later?
                  b3.use Builtin::ProvisionerCleanup
                end
              else
                b3.use Message, :will_not_destroy
              end
            end
          end
        end
      end

      # This action packages the virtual machine into a single box file.
      def self.action_package
        Builder.new.tap do |b|
          b.use Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use action_halt
            b2.use CompressRootFS
            b2.use SetupPackageFiles
            b2.use Vagrant::Action::General::Package
          end
        end
      end

      # This action is called to read the IP of the container. The IP found
      # is expected to be put into the `:machine_ip` key.
      def self.action_fetch_ip
        Builder.new.tap do |b|
          b.use Builtin::ConfigValidate
          b.use FetchIpWithLxcAttach
          b.use FetchIpFromDnsmasqLeases
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Builder.new.tap do |b|
          b.use CheckCreated
          b.use CheckRunning
          b.use Builtin::SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Builder.new.tap do |b|
          b.use CheckCreated
          b.use CheckRunning
          b.use Builtin::SSHRun
        end
      end
    end
  end
end
