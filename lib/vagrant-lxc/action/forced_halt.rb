module Vagrant
  module LXC
    module Action
      class ForcedHalt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].provider.state.id == :running
            env[:ui].info I18n.t("vagrant_lxc.messages.force_shutdown")
            env[:machine].provider.driver.forced_halt
          end

          @app.call(env)
        end
      end
    end
  end
end
