module Vagrant
  module LXC
    module Action
      class ForcedHalt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].provider.state.running?
            env[:ui].info I18n.t("vagrant.actions.vm.halt.force")
            # TODO: Driver#halt is kinda graceful as well, if it doesn't
            #       work we can issue a lxc-stop.
            env[:machine].provider.driver.halt
          end

          @app.call(env)
        end
      end
    end
  end
end
