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

          config.customize 'utsname',
            env[:machine].config.vm.hostname || env[:machine].id

          env[:ui].info I18n.t("vagrant_lxc.messages.starting")
          env[:machine].provider.driver.start(config.customizations)

          @app.call env
        end
      end
    end
  end
end
