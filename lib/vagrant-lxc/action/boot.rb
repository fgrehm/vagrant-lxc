module Vagrant
  module LXC
    module Action
      class Boot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          config = env[:machine].provider_config

          config.customize 'utsname', env[:machine].id

          env[:ui].info I18n.t("vagrant_lxc.messages.starting")
          env[:machine].provider.driver.start(config.customizations)
          raise Vagrant::Errors::VMFailedToBoot if !wait_for_boot

          @app.call env
        end

        # Stolen from on VagrantPlugins::ProviderVirtualBox::Action::Boot
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

            # TODO: Find out if there is a command to check if the machine is
            #       starting, `lxc-monitor` shows this information, but I've
            #       never seen it on `lxc-info` which is what it is being used
            #       to determine container status

            # If the VM is not starting or running, something went wrong
            # and we need to show a useful error.
            state = @env[:machine].provider.state.id
            raise Vagrant::Errors::VMFailedToRun if state != :starting && state != :running

            sleep 2 if !@env["vagrant.test"]
          end

          @env[:ui].error I18n.t("vagrant.actions.vm.boot.failed")
          false
        end
      end
    end
  end
end
