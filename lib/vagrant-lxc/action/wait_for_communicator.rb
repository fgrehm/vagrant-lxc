# This acts like a backport of Vagrant's built in action from 1.3+ for older versions
#   https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/action/builtin/wait_for_communicator.rb
module Vagrant
  module LXC
    module Action
      class WaitForCommunicator
        def initialize(app, env, states = [])
          @app    = app
          @states = states
        end

        def call(env)
          @env = env
          raise Vagrant::Errors::VMFailedToBoot if !wait_for_boot
          @app.call env
        end

        # Stolen from the an old version of VagrantPlugins::ProviderVirtualBox::Action::Boot
        def wait_for_boot
          @env[:ui].info I18n.t("vagrant_lxc.messages.waiting_for_start")

          @env[:machine].config.ssh.max_tries.to_i.times do |i|
            if @env[:machine].communicate.ready?
              @env[:ui].info I18n.t("vagrant_lxc.messages.container_ready")
              return true
            end

            # Return true so that the vm_failed_to_boot error doesn't
            # get shown
            return true if @env[:interrupted]

            # If the VM is not starting or running, something went wrong
            # and we need to show a useful error.
            state = @env[:machine].provider.state.id
            raise Vagrant::Errors::VMFailedToRun unless @states.include?(state)

            sleep 2 if !@env["vagrant.test"]
          end

          @env[:ui].error I18n.t("vagrant.actions.vm.boot.failed")
          false
        end
      end
    end
  end
end
