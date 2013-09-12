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
require 'vagrant-lxc/action/remove_temporary_files'
require 'vagrant-lxc/action/setup_package_files'
require 'vagrant-lxc/action/share_folders'

unless Vagrant::LXC.vagrant_1_3_or_later
  require 'vagrant-lxc/action/wait_for_communicator'
  Vagrant::Action::Builtin.const_set :WaitForCommunicator, Vagrant::LXC::Action::WaitForCommunicator
end

module Vagrant
  module LXC
    module Action
      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Vagrant::Action::Builtin::ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::Provision
          b.use Vagrant::Action::Builtin::EnvSet, :port_collision_repair => true
          b.use Vagrant::Action::Builtin::HandleForwardedPortCollisions
          b.use ShareFolders
          b.use Vagrant::Action::Builtin::SetHostname
          b.use ForwardPorts
          b.use Boot
          b.use Vagrant::Action::Builtin::WaitForCommunicator, [:starting, :running]
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::ConfigValidate
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Vagrant::Action::Builtin::Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use Message, :not_running
                next
              end

              b3.use Vagrant::Action::Builtin::Provision
            end
          end
        end
      end

      # This action starts a container, assuming it is already created and exists.
      # A precondition of this action is that the container exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
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
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::Call, Created do |env, b2|
            if env[:result]
              # TODO: Remove this on / after 0.4
              b2.use Disconnect
              b2.use ClearForwardedPorts
              b2.use RemoveTemporaryFiles
              b2.use Vagrant::Action::Builtin::Call, Vagrant::Action::Builtin::GracefulHalt, :stopped, :running do |env2, b3|
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
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Vagrant::Action::Builtin::Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use Vagrant::Action::Builtin::ConfigValidate
                b3.use Vagrant::Action::Builtin::EnvSet, :force_halt => true
                b3.use action_halt
                b3.use Destroy
                if Vagrant::LXC.vagrant_1_3_or_later
                  b3.use Vagrant::Action::Builtin::ProvisionerCleanup
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
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::Call, Created do |env1, b2|
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
        Vagrant::Action::Builder.new.tap do |b|
          b.use Vagrant::Action::Builtin::ConfigValidate
          b.use FetchIpWithLxcAttach
          b.use FetchIpFromDnsmasqLeases
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckCreated
          b.use CheckRunning
          b.use Vagrant::Action::Builtin::SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckCreated
          b.use CheckRunning
          b.use Vagrant::Action::Builtin::SSHRun
        end
      end
    end
  end
end
