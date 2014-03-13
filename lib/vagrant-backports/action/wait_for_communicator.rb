# This acts like a backport of Vagrant's built in action from 1.3+ for previous version
#   https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/action/builtin/wait_for_communicator.rb
module Vagrant
  module Backports
    module Action
      class WaitForCommunicator
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          raise Vagrant::Errors::VMFailedToBoot if !wait_for_communicator

          @app.call env
        end

        def wait_for_communicator
          max_tries = @env[:machine].config.ssh.max_tries.to_i
          max_tries.times do |i|
            if @env[:machine].communicate.ready?
              @env[:ui].info 'Machine booted and ready!'
              return true
            end

            # Return true so that the vm_failed_to_boot error doesn't
            # get shown
            return true if @env[:interrupted]

            sleep 1 if !@env["vagrant.test"]
          end

          @env[:ui].error I18n.t("vagrant.actions.vm.boot.failed")
          false
        end
      end
    end
  end
end

Vagrant::Action::Builtin.const_set :WaitForCommunicator, Vagrant::Backports::Action::WaitForCommunicator
